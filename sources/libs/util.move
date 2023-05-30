module loyaltychain::util {
  use std::string:: {Self, String};

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
}