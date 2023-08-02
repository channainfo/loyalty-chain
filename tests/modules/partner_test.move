#[test_only]
module loychain::partner_test {


  #[test]
  public fun test_init_create_boards(){

    use sui::test_scenario;

    use loychain::partner::{Self, PartnerBoard, CompanyBoard};

    let owner = @0001;
    let scenario = test_scenario::begin(owner);

    {
      let ctx = test_scenario::ctx(&mut scenario);
      partner::init_create_boards(ctx);

    };

    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let company_board = test_scenario::take_shared<CompanyBoard>(&scenario);

      assert!( partner::partners_count(&partner_board) == 0, 0 );
      assert!( partner::public_partners_count(&partner_board) == 0, 0 );
      assert!( partner::partners_companies_count(&partner_board) == 0, 0 );
      assert!( partner::partners_public_companies_count(&partner_board) == 0, 0 );

      assert!( partner::companies_count(&company_board) == 0, 0 );
      assert!( partner::public_companies_count(&company_board) == 0, 0 );

      test_scenario::return_shared<PartnerBoard>(partner_board);
      test_scenario::return_shared<CompanyBoard>(company_board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_register_partner(){

    use sui::test_scenario;
    use sui::object;

    use std::string::{Self};
    use loychain::partner::{Self, PartnerBoard, Partner, PartnerCap};

    let owner = @0x0001;
    let name = string::utf8(b"CM Market");
    let code = string::utf8(b"CMM");
    let excerpt = string::utf8(b"CM Market: Multi market place");
    let content = string::utf8(b"Provide wide range of services and ecoms");
    let logo_url = string::utf8(b"https://cm-market.io/cmm.png");
    let visibility = 0;
    let token_name = string::utf8(b"CMM");
    let allow_nft_card = 1;

    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      partner::init_create_boards(ctx);
    };

    // Scenario 1: Register a new partner
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,visibility, token_name, owner, allow_nft_card, &mut partner_board, ctx
      );

      // Expect a registration is successful
      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    let effects = test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);

      // PartnerBoard partners_count increase to 1
      assert!(partner::partners_count(&partner_board) == 1, 0);
      // no public exists yet
      assert!(partner::public_partners_count(&partner_board) == 0, 0);

      // Expect a partner is created with correct values
      let partner :&Partner = partner::borrow_partner_by_code(code, &partner_board);
      assert!(partner::partner_name(partner) == name, 0 );
      assert!(partner::partner_code(partner) == code, 0 );
      assert!(partner::partner_excerpt(partner) == excerpt, 0 );
      assert!(partner::partner_content(partner) == content, 0 );
      assert!(partner::partner_logo_url(partner) == logo_url, 0 );
      assert!(partner::partner_visibility(partner) == visibility, 0 );
      assert!(partner::partner_token_name(partner) == token_name, 0 );
      assert!(partner::partner_owner_address(partner) == owner, 0 );
      assert!(partner::partner_companies_count(partner) == 0u64, 0 );

      // Expect partern_cap is owned by the address with correct value
      let partner_cap = test_scenario::take_from_address<PartnerCap>(&scenario, owner);
      assert!(partner::partner_cap_partner_id(&partner_cap) == object::id(partner), 0);

      test_scenario::return_to_address<PartnerCap>(owner, partner_cap);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect 1 event is created
    assert!(test_scenario::num_user_events(&effects) == 1, 0);

    // Scenario2: When try to register with existing partner code
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_partner(
        name, code, excerpt, content, logo_url,visibility, token_name, owner, allow_nft_card, &mut partner_board, ctx
      );

      // Expect a registration will fail
      assert!(result == false, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_register_company(){

    use sui::test_scenario;
    use sui::object::{Self};
    use std::string::{Self};
    use loychain::partner::{Self, CompanyBoard, PartnerBoard};

    let owner = @0001;

    let name = string::utf8(b"Conmigo, LTD.");
    let code = string::utf8(b"CMB");
    let excerpt = string::utf8(b"Ticketing platform for traveller");
    let content = string::utf8(b"The leading ticketing platform");
    let logo_url = string::utf8(b"");
    let visibility = 1;
    let token_name = string::utf8(b"CMG");
    let allow_nft_card = 1;

    let company_name = string::utf8(b"Resort and Spa");
    let company_code = string::utf8(b"RAS");
    let company_excerpt = string::utf8(b"Offer unique experiences!");
    let company_content = string::utf8(b"One of the leading!!!");
    let company_logo_url = string::utf8(b"");

    // Init the module data
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      partner::init_create_boards(ctx);
    };

    // Next transaction to register a partner and expect to be saved.
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      // Already tested
      partner::register_partner(name, code, excerpt, content, logo_url, visibility, token_name, owner, allow_nft_card, &mut partner_board, ctx);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Next transaction to register the company and expect to be saved.
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let company_board = test_scenario::take_shared<CompanyBoard>(&scenario);

      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_company(
        company_name, company_code, company_excerpt, company_content,
        company_logo_url, code, owner, &mut company_board, &mut partner_board, ctx
      );

      assert!(result == true, 0);

      test_scenario::return_shared<CompanyBoard>(company_board);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Next transaction to read and verify that the assets saved correctly
    let effects = test_scenario::next_tx(&mut scenario, owner);
    {
      // Expect partner board is updated with correct data
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      assert!(partner::partners_count(&partner_board) == 1, 0);
      assert!(partner::public_partners_count(&partner_board) == 1, 0);
      assert!(partner::partners_companies_count(&partner_board) == 1, 0);
      assert!(partner::partners_public_companies_count(&partner_board) == 1, 0);

      // Expect company board is updated with correct data
      let company_board = test_scenario::take_shared<CompanyBoard>(&scenario);
      assert!(partner::companies_count(&company_board) == 1, 0);
      assert!(partner::public_companies_count(&company_board) == 1, 0);

      // Expect partner is updated with correct data
      let partner = partner::borrow_partner_by_code(code, &partner_board);
      let partner_id = object::id(partner);
      assert!(partner::partner_companies_count(partner) == 1, 0);

      // Expect a company is created with correct data
      let company = partner::borrow_company_by_code(company_code, &company_board);
      assert!(partner::company_code(company) == company_code, 0);
      assert!(partner::company_name(company) == company_name, 0);
      assert!(partner::company_excerpt(company) == company_excerpt, 0);
      assert!(partner::company_content(company) == company_content, 0);
      assert!(partner::company_logo_url(company) == company_logo_url, 0);
      assert!(partner::company_partner_id(company) == &partner_id, 0);

      test_scenario::return_shared<CompanyBoard>(company_board);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Register the same company, it failed
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let company_board = test_scenario::take_shared<CompanyBoard>(&scenario);

      let ctx = test_scenario::ctx(&mut scenario);

      let result = partner::register_company(
        company_name, company_code, company_excerpt, company_content,
        company_logo_url, code, owner, &mut company_board, &mut partner_board, ctx
      );
      // Expect to failed for the existing company
      assert!(result == false, 0);

      test_scenario::return_shared<CompanyBoard>(company_board);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Expect an event is emitted
    assert!(test_scenario::num_user_events(&effects) == 1, 0);
    test_scenario::end(scenario);
  }
}