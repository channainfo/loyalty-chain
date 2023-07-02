#[test_only]
module loychain::util_test {

  use sui::address::{Self};
  use sui::url::{Url};
  use std::string::{Self, String};
  use std::option::{Self, Option};
  use loychain::util::{Self};

  #[test]
  public fun test_hash_string(){

    let email = std::string::utf8(b"support@loychain.org");

    // bytes normally printout as an address, so we need to create a literal address to represent the bytes
    let expected_address = @0xdc221d6113ecc78c290734af26a29f3673433b5eee6fe5c12b7098bfe2960686;
    let expected: vector<u8> = address::to_bytes(expected_address);

    let hash_value: vector<u8> = util::hash_string(&email);
    assert!(hash_value == expected, 0);
  }

  #[test]
  public fun test_print_with_message(){
    let message = b"Test loychain::util::print with below value: ";
    let value: u64 = 2030u64;
    loychain::util::print(message, &value);
  }

  #[test]
  public fun test_print_without_messge(){
    use std::string:: { Self, String};

    let message = b"";
    let value: String = string::utf8(b"String as value");
    loychain::util::print(message, &value);
  }

  #[test]
  public fun test_try_url_from_string(){

    // Its return Option<Url> with value if string is present
    {
      let value: String = string::utf8(b"https://loychain.sui/");
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

  #[test]
  public fun test_get_name_as_bytes(){
    use loychain::util;
    use loychain::loy::{LOY};

    let expected = b"LOY";
    let result = util::get_name_as_bytes<LOY>();

    assert!(result == expected, 0);
  }

  #[test]
  public fun test_get_name_as_string(){
    use loychain::util;
    use loychain::loy::{LOY};

    let expected = string::utf8(b"LOY");
    let result = util::get_name_as_string<LOY>();

    assert!(result == expected, 0);
  }

  #[test]
  public fun test_get_type_from_bytes(){
    use loychain::util;

    // it returns LOY without fully qualified name
    {
      let expected = b"LOY";
      let value = b"00000000000000000000000000000000::loychain::loy::LOY";

      let result = util::get_type_from_bytes(value);
      assert!(result == expected, 0);
    };

    // it returns LOY
    {
      let expected = b"LOY";
      let value = b"LOY";

      let result = util::get_type_from_bytes(value);
      assert!(result == expected, 0);
    };

  }
}