#[test_only]
module loyaltychain::util_test {

  use sui::address::{Self};
  use sui::url::{Url};
  use std::string::{Self, String};
  use std::option::{Self, Option};
  use loyaltychain::util::{Self};

  #[test]
  public fun test_hash_string(){

    let email = std::string::utf8(b"support@loyaltychain.org");

    let expected_address = @0xa9fa078ae3c843e5c321a6443f5b240c9cf080a3940c2b5463223519281dcecb;
    let expected: vector<u8> = address::to_bytes(expected_address);

    let hash_value: vector<u8> = util::hash_string(&email);
    assert!(hash_value == expected, 0);
  }

  #[test]
  public fun test_print_with_message(){
    let message = b"Test loyaltychain::util::print with below value: ";
    let value: u64 = 2030u64;
    loyaltychain::util::print(message, &value);
  }

  #[test]
  public fun test_print_without_messge(){
    use std::string:: { Self, String};

    let message = b"";
    let value: String = string::utf8(b"String as value");
    loyaltychain::util::print(message, &value);
  }

  #[test]
  public fun test_try_url_from_string(){

    // Its return Option<Url> with value if string is present
    {
      let value: String = string::utf8(b"https://loyaltychain.sui/");
      let url_value: Option<Url> = util::try_url_from_string(&value);
      assert!(option::is_some<Url>(&url_value) == true, 0);
    };

    // It return an empty url if string is not present
    {
      let value: String = string::utf8(b"");
      let url_value: Option<Url> = util::try_url_from_string(&value);
      assert!(option::is_none<Url>(&url_value) == true, 0);
    };

  }
}