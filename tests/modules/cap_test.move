#[test_only]
module loychain::cap_test {

  #[test]
  public fun test_init_create_admin_cap() {
    use sui::test_scenario;
    use loychain::cap::{Self, AdminCap};

    let owner = @0x001;
    let scenario = test_scenario::begin(owner);

    {
      let ctx = test_scenario::ctx(&mut scenario);
      cap::init_create_admin_cap(ctx);
    };

    test_scenario::next_tx(&mut scenario, owner);
    {
      let is_admin_cap = test_scenario::has_most_recent_for_sender<AdminCap>(&mut scenario);
      assert!(is_admin_cap == true, 0);
    };

    test_scenario::end(scenario);
  }
}