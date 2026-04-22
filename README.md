# galactic_trade_authority

`galactic_trade_authority` teaches Ash by following the slow hardening of a
bureaucratic interplanetary trade system.

The series begins with one clean registry and gradually adds local law, faction
power, contractual loopholes, off-ledger evidence, investigation, and scale.
Each lesson stands on its own, but together they follow the same regime as it
tries to turn paperwork into reality.

Each new fracture opens a new Ash idea. The point is not to decorate the ledger
with more tables. The point is to let the Authority become more believable while
every chapter introduces a sharper boundary around official truth.

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

## Final Authority Shape

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

## Beyond the Series

The first five chapters already cover the core Ash arc this series needs:

- resources and actions
- validations and explicit state boundaries
- relationships and route-aware law
- policies and actor-dependent visibility
- layered rule evaluation and contractual exceptions
- soft constraints around parallel evidence models

Ash still has a few deeper branches that could become later chapters or bonus
appendices:

- **Investigation and audit history**: the natural next step once reports and
  official manifests start disagreeing. This is where audit records, approval
  chains, and derived investigative views become first-class.
- **Multi-tenancy**: once the Authority expands across sectors or galaxies, the
  same law engine needs isolated data, isolated policy surfaces, and local rule
  variation without collapsing into a single shared ledger.
- **Interfaces and APIs**: after the domain model is stable, an API or admin UI
  chapter could show how Ash exposes the existing law engine outward without
  relocating the business rules.
- **Persistent data layers**: the lessons currently use ETS because the story is
  about modeling, not storage. A later appendix could show the same domain moved
  onto Postgres with minimal conceptual drift.

Those are worth teaching. They simply sit one layer past the story this series
is telling first.

## Tooling

The repo is pinned with `.tool-versions` so the lessons run against an
asdf-managed Elixir and Erlang toolchain that matches the Ash versions used in
the series.

If `mix` is not available in your shell, configure your asdf shims first rather
than prefixing each command manually.

For the Livebook companions, use the repo-root helper scripts:

```bash
./scripts/install_livebook.sh
./scripts/livebook.sh server livebooks
```

## Start Here

Begin with [`01_order`](./01_order/README.md).

That chapter introduces the central GTA contract:

```elixir
Shipment
|> Ash.Changeset.for_create(
  :register,
  %{manifest_number: "GTA-1001", quantity: 10, declared_value: 500}
)
|> Ash.create()
```

Before the Authority accumulates local law, faction power, contractual
loopholes, and off-ledger evidence, it first needs one clean registry whose
legal boundary is explicit and testable.
