# Getting started with Loyalty Chain

**LOY** is the native token. Checkout our white paper: <https://github.com/channainfo/loyalty-chain/blob/master/docs/whitepaper.md>

Run test

```sh
sui move test
```

## Sui CLI

Loychain tests and runs on the following sui version

```sh
sui --version
sui 1.5.0-c9b896c0b
```

## Objects On-chain

### Implemented

```plaintext
- AdminCap[]
- Partner: [name, code, excerpt, content, logo, is_public, token_name, owner_address, companies_count]
- Company: [name, code, excerpt, content, logo_url, is_public, members_count, owner_address, partner_id]
- Member: [code, owner_address, first_name, last_name, nick_name]
- LOY Token: [LOY]
- NFTCardTier: [name, description, image_url, benefit, partner_id]
- NFTCardType: [name, image_url, max_supply, current_supply, current_issued_number, card_tier_id, partner_id]
- NFTCard: [card_tier_id, card_type_id, issued_number, issued_at, benefit, accumulated_value]
```

### Use Cases

- Membership card ( Benefit will be aggregate to the account owner)
- Voucher ( Self contain product exchange directly for products or services )

#### Membership Card

1. **Point System Card:** Issue an nft card with a type of "point", everytime a customer makes a purchase, a certain number of points will be minted and transfer to the customer.

2. **Discount Card:** Issue an nft card with a type "disccount", everytime a customer make a purchase, the customer will get a disount amount.

3. **Loyalty Card:** Issue an nft card with a type "loyalty", everytime a customer make a purchase, a certain number of points will be minted ( based on tier) and transfer to the customer. If the point reach the tier, upgrade the tier the customer tier accordingly.

#### Voucher

1. **Claim For Service:** Issue an nft card with a type of "vouchers", everytime users use the service or exchange for a product, burn a number of point from the voucher(self-contained).

## Interoperabilities

- Presale
- Swap
- Escrow
- Auction
- Marketplace

## Activities On Chain

### Initialization

- init admin cap
- init parnter ( partner listing,company listing)
- init member ( member listing )

### Admin Actions

Required the admin cap

- Register a partner
- Register a company
- Register a member

### Partner Actions

- Register a company
- Manage NFT
- Issue an NFT card
- Inquiry

### Member Actions

- Register for a membership(Self custody)
- Receive coin(claim)
- Transfer coin to an address
- Receive NFT(claim)
- Transfer NFT

## Event

- Partner registration
- Company registration
- Member registration

## Deployment

```sh
sui client active-env
sui client active-address
sui client publish --gas-budget 300500500 > logs/publish-testnet.log

```

The publish output is save [logs/publish-testnet.log](https://github.com/channainfo/loyalty-chain/tree/master/logs/publish-testnet.log)

### Created object

- Owner address: 0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed

#### package::UpgradeCap

```log
Object {
    "type": String("created"),
    "sender": String("0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed"),
    "owner": Object {
        "AddressOwner": String("0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed"),
    },
    "objectType": String("0x2::package::UpgradeCap"),
    "objectId": String("0x48dd6484330b3b465a481f9251b06cb5ea8fc2d0efdca2c82a79eac1a1052574"),
    "version": String("43"),
    "digest": String("2rA4Ks9p9XKRoCGJZ4eoffBMRxHL5KmxEsah34DjwTdt"),
}
```

#### AdminCap

```log
Object {
    "type": String("created"),
    "sender": String("0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed"),
    "owner": Object {
        "AddressOwner": String("0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed"),
    },
    "objectType": String("0xdc5716b2e1170a2c755779f1d1a1c0d741dad99ad14f3c2b8212d9000cb253f6::cap::AdminCap"),
    "objectId": String("0x8a30fa6da32e8af5c4d43c627d7ea364e418da6a2813f38b2fa1e220be59a48c"),
    "version": String("43"),
    "digest": String("AYtwRmZuB3uyeBRCAfJso8atXh6nwXQ1i5WyfLH8mRWa"),
}

```

#### LOY

TreasuryCap&lt;LOY&gt;

```log
Object {
    "type": String("created"),
    "sender": String("0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed"),
    "owner": Object {
        "AddressOwner": String("0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed"),
    },
    "objectType": String("0x2::coin::TreasuryCap<0xdc5716b2e1170a2c755779f1d1a1c0d741dad99ad14f3c2b8212d9000cb253f6::loy::LOY>"),
    "objectId": String("0xb2674f71b8ce7371563155a57d459268459a39c7e480bb57f4f46be73213a47f"),
    "version": String("43"),
    "digest": String("GHmBfijgtqDxHJe8mbjyQNtGd4Za3ngJC4n9A6JBrkEk"),
}
```

CoinMetadata&lt;LOY&gt;

```log
Object {
    "type": String("created"),
    "sender": String("0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed"),
    "owner": String("Immutable"),
    "objectType": String("0x2::coin::CoinMetadata<0xdc5716b2e1170a2c755779f1d1a1c0d741dad99ad14f3c2b8212d9000cb253f6::loy::LOY>"),
    "objectId": String("0xc5d3464cab82b1dfe2bf69439d21a0a675def3e8e01de9b2d8bb02dedd1cac16"),
    "version": String("43"),
    "digest": String("HrgxiK3QkfjQPdQjjiZ3RcBc2aKExmezGvjiUzABXwKr"),
}
```

#### MemberBoard

```log
Object {
    "type": String("created"),
    "sender": String("0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed"),
    "owner": Object {
        "Shared": Object {
            "initial_shared_version": Number(43),
        },
    },
    "objectType": String("0xdc5716b2e1170a2c755779f1d1a1c0d741dad99ad14f3c2b8212d9000cb253f6::member::MemberBoard"),
    "objectId": String("0x445e30786f7cba14ee166375891ab8710bd51201513049b1a22631ff67a7955f"),
    "version": String("43"),
    "digest": String("RLXjUARfXg8NQ9StbcfhrSKsHDvvqCBBJsuFvqoHfyF"),
}
```

#### Company board

```log
Object {
    "type": String("created"),
    "sender": String("0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed"),
    "owner": Object {
        "Shared": Object {
            "initial_shared_version": Number(43),
        },
    },
    "objectType": String("0xdc5716b2e1170a2c755779f1d1a1c0d741dad99ad14f3c2b8212d9000cb253f6::partner::CompanyBoard"),
    "objectId": String("0x642d6851670caca358e797bcf3931676f8728451bd2193e400be272a93021fbf"),
    "version": String("43"),
    "digest": String("8aaBvhch7bzFFr3fDSr6YqqK8uG98TrNXG3fyeotkcri"),
}

```

#### Partner board

```log
Object {
    "type": String("created"),
    "sender": String("0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed"),
    "owner": Object {
        "Shared": Object {
            "initial_shared_version": Number(43),
        },
    },
    "objectType": String("0xdc5716b2e1170a2c755779f1d1a1c0d741dad99ad14f3c2b8212d9000cb253f6::partner::PartnerBoard"),
    "objectId": String("0x7ea528fcbb46f21443baf3ca0fa958d56ab46201e54459579e61ebb843827682"),
    "version": String("43"),
    "digest": String("FBpE2dpSeSL6dGzx8yiWHJaJ9cp8qLxiYni3BTMfukRh"),
}

```

### PackageID

```log
Object {
    "type": String("published"),
    "packageId": String("0xdc5716b2e1170a2c755779f1d1a1c0d741dad99ad14f3c2b8212d9000cb253f6"),
    "version": String("1"),
    "digest": String("DXFzjPPTFtFVfMjtt43o1WRjBoaPTFWMjzL3efyc5uUr"),
    "modules": Array [
        String("cap"),
        String("loy"),
        String("main"),
        String("market_place"),
        String("member"),
        String("member_nft"),
        String("member_token"),
        String("nft"),
        String("partner"),
        String("partner_nft"),
        String("partner_order"),
        String("partner_token"),
        String("partner_treasury"),
        String("token_managable"),
        String("util"),
    ],
}
```

### Explorer

- PackageID: 0xdc5716b2e1170a2c755779f1d1a1c0d741dad99ad14f3c2b8212d9000cb253f6 <https://suiexplorer.com/object/0xdc5716b2e1170a2c755779f1d1a1c0d741dad99ad14f3c2b8212d9000cb253f6?network=testnet>
- Transaction Block (Digest): 2GQuaQ5pySx2SGqgRsX4ruYe9aWVwykYLJrMd7GuAnfT <https://suiexplorer.com/txblock/2GQuaQ5pySx2SGqgRsX4ruYe9aWVwykYLJrMd7GuAnfT?network=testnet>
- Owner address: 0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed <https://suiexplorer.com/address/0xba841936a6f94c56efa97156f49479396e92fcf6395d5f80aaa93843542389ed?network=testnet>

## References

### SUI

- Move Std: <https://github.com/MystenLabs/sui/tree/main/crates/sui-framework/packages/move-stdlib/sources>
- Move Lang Ref: <https://github.com/move-language/move/tree/main/language/documentation/book/src>
- SUI Framework: <https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/packages/sui-framework/sources/dynamic_object_field.move>
- SUI Sample Code: <https://github.com/MystenLabs/sui/tree/main/sui_programmability/examples/nfts>
- Test SUI Framework: <https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/packages/sui-framework/sources/test/test_scenario.move#L209>
- Best Practises: <https://docs.sui.io/testnet/build/dev_cheat_sheet>

### Awesome Move

- Awesome: <https://medium.com/@fidika/aptos-vs-sui-detailed-dev-comparison-5d24df53eee8>
