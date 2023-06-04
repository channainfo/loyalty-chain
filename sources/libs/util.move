module loyaltychain::util {
  use sui::url::{Self, Url};
  use std::string:: {Self, String};
  use std::option::{Self, Option};

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
}