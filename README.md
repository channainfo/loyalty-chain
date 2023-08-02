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

## Interact with the LOY

We've built a client here: <https://github.com/channainfo/loy-client>

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

- Owner address: 0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f

#### package::UpgradeCap

```log
Object {
    "type": String("created"),
    "sender": String("0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f"),
    "owner": Object {
        "AddressOwner": String("0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f"),
    },
    "objectType": String("0x2::package::UpgradeCap"),
    "objectId": String("0xdc1f11f69e52934dc955984b76df13ae86ed0ef7ae35406d9f108bcdbae53bf0"),
    "version": String("451"),
    "digest": String("7kT9Q5t4U5uvHyK9kqhA9VL6JiZjAWv4vT5PGtWbX1HH"),
}
```

#### AdminCap

```log
Object {
    "type": String("created"),
    "sender": String("0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f"),
    "owner": Object {
        "AddressOwner": String("0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f"),
    },
    "objectType": String("0xa3372200d2719a4f4b15f471380403c23d8e9dfcc99670b3d8e70eb3e0d1b935::cap::AdminCap"),
    "objectId": String("0xa935644519ce3977c3681b46b82f2f9515c93d5ab4de70ff8c5b9f65fbb28f48"),
    "version": String("451"),
    "digest": String("EpmCyMT19cRpNbdQhM2Xcw2fP2G8MeLE5dpHy5nE7m3p"),
}

```

#### LOY

TreasuryCap&lt;LOY&gt;

```log
   Object {
    "type": String("created"),
    "sender": String("0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f"),
    "owner": Object {
        "AddressOwner": String("0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f"),
    },
    "objectType": String("0x2::coin::TreasuryCap<0xa3372200d2719a4f4b15f471380403c23d8e9dfcc99670b3d8e70eb3e0d1b935::loy::LOY>"),
    "objectId": String("0x92e3bf963286e2edaf8422001c0295e177c34e7c20014f2db5b5c9eb198c29f5"),
    "version": String("451"),
    "digest": String("2Z944GS77jxatszTRinyXNZfJzor4etzXqTHdRQPdocp"),
}
```

CoinMetadata&lt;LOY&gt;

```log
Object {
    "type": String("created"),
    "sender": String("0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f"),
    "owner": String("Immutable"),
    "objectType": String("0x2::coin::CoinMetadata<0xa3372200d2719a4f4b15f471380403c23d8e9dfcc99670b3d8e70eb3e0d1b935::loy::LOY>"),
    "objectId": String("0x647e02f7bd0f305aefbe5016235f9627af1b4653a2cb0fb33a132d47cd886a3b"),
    "version": String("451"),
    "digest": String("GdQc4xLZwCuhQVj2QBiCiSmgfkjf9d13orscQatyosEa"),
}
```

#### MemberBoard

```log
Object {
    "type": String("created"),
    "sender": String("0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f"),
    "owner": Object {
        "Shared": Object {
            "initial_shared_version": Number(451),
        },
    },
    "objectType": String("0xa3372200d2719a4f4b15f471380403c23d8e9dfcc99670b3d8e70eb3e0d1b935::member::MemberBoard"),
    "objectId": String("0xfa5c873e714f95be50b5b63c62c0ae249cb8aae596191d6321ccfc51237d2172"),
    "version": String("451"),
    "digest": String("9tcamipqZKYzQeNFY9ge7wq5VwVuZUpmsbJyrCYR2pqQ"),
}
```

#### Company board

```log
Object {
    "type": String("created"),
    "sender": String("0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f"),
    "owner": Object {
        "Shared": Object {
            "initial_shared_version": Number(451),
        },
    },
    "objectType": String("0xa3372200d2719a4f4b15f471380403c23d8e9dfcc99670b3d8e70eb3e0d1b935::partner::CompanyBoard"),
    "objectId": String("0xfb1cb7788f5625e0992795dc501b8dbd1764501702502f32347522c7a8bf302b"),
    "version": String("451"),
    "digest": String("FBTcgZJjW34QFSFtnWnwVZBMGkrnkpL9SMHskAh5NvCD"),
}

```

#### Partner board

```log
Object {
    "type": String("created"),
    "sender": String("0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f"),
    "owner": Object {
        "Shared": Object {
            "initial_shared_version": Number(451),
        },
    },
    "objectType": String("0xa3372200d2719a4f4b15f471380403c23d8e9dfcc99670b3d8e70eb3e0d1b935::partner::PartnerBoard"),
    "objectId": String("0xae879834b33cfc4079b0162d602f0fb026de8a3f05200575196d091e139180bf"),
    "version": String("451"),
    "digest": String("DK2UJEXMuAQJXt1663dbi8igEUx8XvEKGDDpAxLgNUGQ"),
}

```

### PackageID

```log
 Object {
    "type": String("published"),
    "packageId": String("0xa3372200d2719a4f4b15f471380403c23d8e9dfcc99670b3d8e70eb3e0d1b935"),
    "version": String("1"),
    "digest": String("CJxJsSYwucz7G71mSQoV3ESDtYCDBoGTBxvDGjTQxoP6"),
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

- PackageID: 0xa3372200d2719a4f4b15f471380403c23d8e9dfcc99670b3d8e70eb3e0d1b935 <https://suiexplorer.com/object/0xa3372200d2719a4f4b15f471380403c23d8e9dfcc99670b3d8e70eb3e0d1b935?network=testnet>
- Transaction Block (Digest): 51YKmX8dH2ynMGHMo6Z8H194sWmNeBeFGiBNVM4scVoK <https://suiexplorer.com/txblock/51YKmX8dH2ynMGHMo6Z8H194sWmNeBeFGiBNVM4scVoK?network=testnet>
- Owner address: 0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f <https://suiexplorer.com/address/0xcadc10a1a41194cbd9f5fc39c83cc0393c100aab35a9f7c5fb1e1e52b88af98f?network=testnet>

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
