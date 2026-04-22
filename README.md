# galactic_trade_authority

`galactic_trade_authority` teaches Ash by following the slow hardening of a
bureaucratic interplanetary trade system.

The series begins with one clean registry and gradually adds local law, faction
power, contractual loopholes, off-ledger evidence, investigation, and scale.
Each lesson stands on its own, but together they follow the same regime as it
tries to turn paperwork into reality.

## Interactive Companions

Livebook companions for the series live in [`livebooks/`](./livebooks/README.md).

- [`livebooks/01_order.livemd`](./livebooks/01_order.livemd)
- [`livebooks/02_planetary_law.livemd`](./livebooks/02_planetary_law.livemd)
- [`livebooks/03_faction_power.livemd`](./livebooks/03_faction_power.livemd)
- [`livebooks/04_contract_loopholes.livemd`](./livebooks/04_contract_loopholes.livemd)
- [`livebooks/05_shadow_market.livemd`](./livebooks/05_shadow_market.livemd)

## The Journey

Each lesson is its own standalone Mix project, but the world and Ash concepts
advance together:

1. [`01_order`](./01_order/README.md)
   The Authority creates a single official registry, and the reader learns
   resources, actions, and validations.
2. [`02_planetary_law`](./02_planetary_law/README.md)
   Planets inject local law into shipment registration, and the reader learns
   relationships, custom validations, and custom changes.
3. [`03_faction_power`](./03_faction_power/README.md)
   Factions change what actors may create and see, and the reader learns
   authorization policies and filtered reads.
4. [`04_contract_loopholes`](./04_contract_loopholes/README.md)
   Contracts override normal rule outcomes, and the reader learns layered action
   logic and derived official results.
5. [`05_shadow_market`](./05_shadow_market/README.md)
   Off-ledger evidence diverges from official truth, and the reader learns
   optional relationships, soft constraints, and discrepancy classification.

## Current System Shape

By chapter 5 the Authority looks like this:

```text
ShadowMarket.Registry
|- Trader
|- Planet
|- TradeResource
|- Shipment
`- ShadowReport
```

That shape keeps the official ledger narrow while adding a separate resource for
evidence that never earned legal status.

The repo root holds the series guide, helper scripts, and interactive notebooks.
Each chapter owns its own code, dependencies, and tests.

## Tooling

For the Livebook companions, use the repo-root helper scripts:

```bash
./scripts/install_livebook.sh
./scripts/livebook.sh server livebooks
```

## Start Here

Begin with [`01_order`](./01_order/README.md), then continue through
[`02_planetary_law`](./02_planetary_law/README.md) and
[`03_faction_power`](./03_faction_power/README.md), then
[`04_contract_loopholes`](./04_contract_loopholes/README.md), then
[`05_shadow_market`](./05_shadow_market/README.md).

The early chapters establish the core GTA rule:

> If a shipment fails validation, it is legally considered never to have existed.

Ash is the mechanism that makes that sentence executable, even after local law,
faction power, negotiated exceptions, and off-ledger evidence start bending the
ledger around its edges.
