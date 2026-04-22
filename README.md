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

## Current System Shape

By chapter 3 the Authority looks like this:

```text
FactionPower.Registry
|- Trader
`- Shipment
```

That shape is intentionally compact. It is enough to make actor-dependent power
feel real without burying the lesson under the contract logic that comes next.

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
[`03_faction_power`](./03_faction_power/README.md).

That chapter introduces the core GTA rule:

> If a shipment fails validation, it is legally considered never to have existed.

Ash is the mechanism that makes that sentence executable, even after local law
and faction power start bending who gets to act on the ledger.
