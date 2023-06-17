# Getting started with Loyalty Chain

LOY Is the native token for this Loyaltychain

Run test

```sh
sui move test
```

## Objects On-chain

### Implemented

- AdminCap
- Partner (name, code, excerpt, content, logo, is_public, token_name, owner_address, companies_count)
- Company( name, code, excerpt, content, logo_url, is_public, members_count, owner_address, partner_id )
- Member( code, owner_address, first_name, last_name, nickname, [companies], [coins])

- LOY token
- NFTCardTier(name, description, image_url, benefit, partner_id)
- NFTCardType(name, image_url, max_supply, current_supply, current_issued_number, benefit, capped_amount, card_tier_id, partner_id)
- NFTCard(card_tier_id, card_type_id, issued_number, issued_at)

### Usecases

#### Point System

Issue an nft card with a type of "point", everytime a customer makes a purchase, a certain number of points will be minted and transfer to the customer.

#### Discount Card

Issue an nft card with a type "disccount", everytime a customer make a purchase, check the data onchain to get the discount.

#### Loyalty

Issue an nft card with a type "loyalty", everytime a customer purchase increase, increase an activity count and upgrade the tier accordingly.

#### Voucher

Issue an nft card with a type of "vouchers", everytime users use the service, burn a number of point from the voucher.

## Interoperability

- Presale
- Swap
- Escrow
- Auction
- Marketplace

## Activity On-chain

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

## References

### SUI

- The move lang stdlib: <https://github.com/MystenLabs/sui/tree/main/crates/sui-framework/packages/move-stdlib/sources>
- The move lang ref: <https://github.com/move-language/move/tree/main/language/documentation/book/src>
- Framework: <https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/packages/sui-framework/sources/dynamic_object_field.move>
- SUI Example: <https://examples.sui.io/basics/events.html>
- SUI Sample code: <https://github.com/MystenLabs/sui/tree/main/sui_programmability/examples/nfts>
- Time: <https://docs.sui.io/build/move/time>
- Test: <https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/packages/sui-framework/sources/test/test_scenario.move#L209>
