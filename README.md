# Getting started with Loyalty Chain

LOY Is the native token for this Loyaltychain

Run test

```sh
sui move test
```

## Objects on chain

- AdminCap, CompanyCap
- Company( name, logo_url, description, token_name, total_members, owner_id )
- Member( code, owner_address, first_name, last_name, nickname, [companies], [coins])
- RewardType(loyalty, cashback)
- Reward(company_id, member_id, total_coin, reward_type, locked)
- Orders( member_id, company_id, number, created_at)
- LineItems ( order_id, name, amount )
- Store (company_id, name, description)
- Product (name, descripton, url, price, redeemable_amount, company_id, partner_id)
- Points (account_id, total_point, redeems_count, rewards_count)
- Voucher presale (total_point, price_coin, scratched)
- Token lock and staking

Coin can be locked for certain amount of time

### Public entries

- Register a company ( AdminCap )
- Company register a member ( CompanyCap )
- Member registration to a company
- EarnPoint(CompanyCap)
- UsePoint(CompanyCap)
- SendPoint

### Event

## References

### SUI

- The move lang stdlib: <https://github.com/MystenLabs/sui/tree/main/crates/sui-framework/packages/move-stdlib/sources>
- The move lang ref: <https://github.com/move-language/move/tree/main/language/documentation/book/src>
- Framework: <https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/packages/sui-framework/sources/dynamic_object_field.move>
- SUI Example: <https://examples.sui.io/basics/events.html>
- SUI Sample code: <https://github.com/MystenLabs/sui/tree/main/sui_programmability/examples/nfts>
- Time: <https://docs.sui.io/build/move/time>
- Test: <https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/packages/sui-framework/sources/test/test_scenario.move#L209>
