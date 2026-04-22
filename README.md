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

## The Journey

Each lesson is its own standalone Mix project, but the world and Ash concepts
advance together:

1. [`01_order`](./01_order/README.md)
   The Authority creates a single official registry, and the reader learns
   resources, actions, and validations.

## Final System Shape

The early Authority in chapter 1 looks like this:

```text
Order.Registry
|- Trader
|- Planet
|- TradeResource
`- Shipment
```

That shape is intentionally small. It is enough to make the legal registry feel
real without burying the lesson under later exceptions.

The repo root holds the series guide, helper scripts, and interactive notebooks.
Each chapter owns its own code, dependencies, and tests.

## Tooling

For the Livebook companions, use the repo-root helper scripts:

```bash
./scripts/install_livebook.sh
./scripts/livebook.sh server livebooks
```

## Start Here

Begin with [`01_order`](./01_order/README.md).

That chapter introduces the core GTA rule:

> If a shipment fails validation, it is legally considered never to have existed.

Ash is the mechanism that makes that sentence executable.
