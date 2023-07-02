module loychain::util {
  use sui::url::{Self, Url};
  use std::string:: {Self, String};
  use std::option::{Self, Option};
  use std::type_name;

  public fun hash_string(value: &String): vector<u8> {
    let hash :vector<u8> = std::hash::sha3_256(*std::string::bytes(value));
    hash
  }

  public fun print<T>(message: vector<u8>, value: &T) {
    std::debug::print(&string::utf8(b"***************************************************"));

    if(message != b"")
      std::debug::print(&string::utf8(message));

    std::debug::print<T>(value);
  }

  public fun try_url_from_string(value: &String): Option<Url> {
    let value_url = if(string::length(value) == 0) {
      option::none<Url>()
    }else {
      let url = url::new_unsafe_from_bytes(*string::bytes(value));
      option::some<Url>(url)
    };

    value_url
  }

  public fun get_name_as_bytes<T>(): vector<u8>{
    let name: std::ascii::String = type_name::into_string(type_name::get<T>());
    let value = std::ascii::into_bytes(name);
    get_type_from_bytes(value)
  }

  public fun get_name_as_string<T>(): String{
    let name: vector<u8> = get_name_as_bytes<T>();
    string::utf8(name)
  }

  // let value = b"00000000000000000000000000000001::loychain::loy::LOY";
  // let expected = b"LOY";
  public fun get_type_from_bytes(name: vector<u8>): vector<u8> {
    // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/packages/move-stdlib/sources/type_name.move#L11
    let ascii_colon = 58u8;
    let count = std::vector::length(&name);

    let i = count;
    let type_name = b"";

    while(i > 0 ) {
      let char = std::vector::borrow(&name, i-1);
      if (*char == ascii_colon) {
        break
      };

      std::vector::insert(&mut type_name, *char, 0);
      i = i - 1;
    };
    type_name
  }

}