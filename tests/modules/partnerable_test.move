#[test_only]
module loyaltychain::partnerable_test {


  #[test]
  public fun test_init_create_boards(){

    use sui::test_scenario;

    use loyaltychain::partnerable::{Self, PartnerBoard, CompanyBoard};

    let owner = @0001;
    let scenario = test_scenario::begin(owner);

    {
      let ctx = test_scenario::ctx(&mut scenario);
      partnerable::init_create_boards(ctx);

    };

    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let company_board = test_scenario::take_shared<CompanyBoard>(&scenario);

      assert!( partnerable::partners_count(&partner_board) == 0, 0 );
      assert!( partnerable::public_partners_count(&partner_board) == 0, 0 );
      assert!( partnerable::partners_companies_count(&partner_board) == 0, 0 );
      assert!( partnerable::partners_public_companies_count(&partner_board) == 0, 0 );

      assert!( partnerable::companies_count(&company_board) == 0, 0 );
      assert!( partnerable::public_companies_count(&company_board) == 0, 0 );

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
    use loyaltychain::partnerable::{Self, PartnerBoard, Partner, PartnerCap};

    let owner = @0x0001;
    let name = string::utf8(b"CM Market");
    let code = string::utf8(b"CMM");
    let excerpt = string::utf8(b"CM Market: Multi market place");
    let content = string::utf8(b"Provide wide range of services and ecoms");
    let logo_url = string::utf8(b"https://cm-market.io/cmm.png");
    let is_public = false;
    let token_name = string::utf8(b"CMM");

    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      partnerable::init_create_boards(ctx);
    };

    // Scenario 1: Register a new partner
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      let result = partnerable::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, owner, &mut partner_board, ctx
      );

      // Expect a registration is successful
      assert!(result == true, 0);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    let effects = test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);

      // PartnerBoard partners_count increase to 1
      assert!(partnerable::partners_count(&partner_board) == 1, 0);
      // no public exists yet
      assert!(partnerable::public_partners_count(&partner_board) == 0, 0);

      // Expect a partner is created with correct values
      let partner :&Partner = partnerable::borrow_partner_by_code(code, &partner_board);
      assert!(partnerable::partner_name(partner) == name, 0 );
      assert!(partnerable::partner_code(partner) == code, 0 );
      assert!(partnerable::partner_excerpt(partner) == excerpt, 0 );
      assert!(partnerable::partner_content(partner) == content, 0 );
      assert!(partnerable::partner_logo_url(partner) == logo_url, 0 );
      assert!(partnerable::partner_is_public(partner) == is_public, 0 );
      assert!(partnerable::partner_token_name(partner) == token_name, 0 );
      assert!(partnerable::partner_owner_address(partner) == owner, 0 );
      assert!(partnerable::partner_companies_count(partner) == 0u64, 0 );

      // Expect partern_cap is owned by the address with correct value
      let partner_cap = test_scenario::take_from_address<PartnerCap>(&scenario, owner);
      assert!(partnerable::partner_cap_partner_id(&partner_cap) == object::id(partner), 0);

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

      let result = partnerable::register_partner(
        name, code, excerpt, content, logo_url,is_public, token_name, owner, &mut partner_board, ctx
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
    use loyaltychain::partnerable::{Self, CompanyBoard, PartnerBoard};

    let owner = @0001;

    let name = string::utf8(b"Conmigo, LTD.");
    let code = string::utf8(b"CMB");
    let excerpt = string::utf8(b"Ticketing platform for traveller");
    let content = string::utf8(b"The leading ticketing platform");
    let logo_url = string::utf8(b"");
    let is_public = true;
    let token_name = string::utf8(b"CMG");

    let company_name = string::utf8(b"Resort and Spa");
    let company_code = string::utf8(b"RAS");
    let company_excerpt = string::utf8(b"Offer unique experiences!");
    let company_content = string::utf8(b"One of the leading!!!");
    let company_logo_url = string::utf8(b"");

    // Init the module data
    let scenario = test_scenario::begin(owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      partnerable::init_create_boards(ctx);
    };

    // Next transaction to register a partner and expect to be saved.
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      // Already tested
      partnerable::register_partner(name, code, excerpt, content, logo_url, is_public, token_name,owner,  &mut partner_board, ctx);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Next transaction to register the company and expect to be saved.
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let company_board = test_scenario::take_shared<CompanyBoard>(&scenario);

      let ctx = test_scenario::ctx(&mut scenario);

      let result = partnerable::register_company(
        company_name, company_code, company_excerpt, company_content,
        company_logo_url, code, &mut company_board, &mut partner_board, ctx
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
      assert!(partnerable::partners_count(&partner_board) == 1, 0);
      assert!(partnerable::public_partners_count(&partner_board) == 1, 0);
      assert!(partnerable::partners_companies_count(&partner_board) == 1, 0);
      assert!(partnerable::partners_public_companies_count(&partner_board) == 1, 0);

      // Expect company board is updated with correct data
      let company_board = test_scenario::take_shared<CompanyBoard>(&scenario);
      assert!(partnerable::companies_count(&company_board) == 1, 0);
      assert!(partnerable::public_companies_count(&company_board) == 1, 0);

      // Expect partner is updated with correct data
      let partner = partnerable::borrow_partner_by_code(code, &partner_board);
      let partner_id = object::id(partner);
      assert!(partnerable::partner_companies_count(partner) == 1, 0);

      // Expect a company is created with correct data
      let company = partnerable::borrow_company_by_code(company_code, &company_board);
      assert!(partnerable::company_code(company) == company_code, 0);
      assert!(partnerable::company_name(company) == company_name, 0);
      assert!(partnerable::company_excerpt(company) == company_excerpt, 0);
      assert!(partnerable::company_content(company) == company_content, 0);
      assert!(partnerable::company_logo_url(company) == company_logo_url, 0);
      assert!(partnerable::company_partner_id(company) == &partner_id, 0);

      test_scenario::return_shared<CompanyBoard>(company_board);
      test_scenario::return_shared<PartnerBoard>(partner_board);
    };

    // Register the same company, it failed
    test_scenario::next_tx(&mut scenario, owner);
    {
      let partner_board = test_scenario::take_shared<PartnerBoard>(&scenario);
      let company_board = test_scenario::take_shared<CompanyBoard>(&scenario);

      let ctx = test_scenario::ctx(&mut scenario);

      let result = partnerable::register_company(
        company_name, company_code, company_excerpt, company_content,
        company_logo_url, code, &mut company_board, &mut partner_board, ctx
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