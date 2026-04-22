# galactic_trade_authority

`galactic_trade_authority` follows the slow hardening of a bureaucratic
interplanetary trade system.

The Authority begins with one clean registry. One lawbook. One official ledger.
Then the cracks arrive one by one: local law, faction leverage, contractual
loopholes, off-ledger evidence, investigation, and scale.

Each chapter is a standalone Mix project, but the same regime keeps hardening
through all of them. The paperwork stays recognizable. The pressure does not.

## Interactive Companions

Livebook companions for the full registry live in [`livebooks/`](./livebooks/README.md).

- [`livebooks/01_order.livemd`](./livebooks/01_order.livemd)
- [`livebooks/02_planetary_law.livemd`](./livebooks/02_planetary_law.livemd)
- [`livebooks/03_faction_power.livemd`](./livebooks/03_faction_power.livemd)
- [`livebooks/04_contract_loopholes.livemd`](./livebooks/04_contract_loopholes.livemd)
- [`livebooks/05_shadow_market.livemd`](./livebooks/05_shadow_market.livemd)
- [`livebooks/06_investigation.livemd`](./livebooks/06_investigation.livemd)
- [`livebooks/07_multi_tenancy.livemd`](./livebooks/07_multi_tenancy.livemd)

## The Journey

The Authority keeps the same identity from beginning to end. Each directory is a
self-contained checkpoint in the same worsening bureaucracy:

1. [`01_order`](./01_order/README.md)
   The Authority opens one official registry and fixes the first legal boundary
   around shipments.
2. [`02_planetary_law`](./02_planetary_law/README.md)
   Planets inject local law into shipment registration, and the route itself
   starts changing what the ledger will accept.
3. [`03_faction_power`](./03_faction_power/README.md)
   Factions change what actors may create and see, and the same ledger stops
   looking neutral from every side.
4. [`04_contract_loopholes`](./04_contract_loopholes/README.md)
   Contracts override normal rule outcomes, and official truth starts bending to
   paper exceptions.
5. [`05_shadow_market`](./05_shadow_market/README.md)
   Off-ledger evidence diverges from official truth, and the registry has to
   preserve suspicion without promoting it to law.
6. [`06_investigation`](./06_investigation/README.md)
   The Authority reconstructs who approved and who later challenged a manifest,
   and the ledger becomes answerable to memory.
7. [`07_multi_tenancy`](./07_multi_tenancy/README.md)
   The same Authority expands across isolated sectors, and identical paperwork
   is no longer allowed to imply shared truth.

## Final Authority Shape

By the time the Authority crosses sectors, it looks roughly like this:

```text
Sector Tenant ("sol")
`- GalacticTradeAuthority.Registry
   |- Trader
   |- Planet
   |- TradeResource
   |- PlanetRule
   |- Contract
   |- Shipment
   |- ShadowReport
   `- AuditRecord

Sector Tenant ("perseus")
`- GalacticTradeAuthority.Registry
   |- Trader
   |- Planet
   |- TradeResource
   |- PlanetRule
   |- Contract
   |- Shipment
   |- ShadowReport
   `- AuditRecord
```

The repetition is the point. By then, the same law engine has to run more than
once without the sectors sharing official truth by accident.

## Beyond This Authority

The seven chapters already carry the Authority through the core pressures this
story needs:

- resources and actions
- validations and explicit state boundaries
- relationships and route-aware law
- policies and actor-dependent visibility
- layered rule evaluation and contractual exceptions
- soft constraints around parallel evidence models
- audit timelines and derived case views
- multitenancy and sector isolation

Ash still has a few deeper branches that could become appendices later:

- **Interfaces and APIs**: after the domain model is stable, an API or admin UI
  chapter could show how Ash exposes the existing law engine outward without
  relocating the business rules.
- **Persistent data layers**: the lessons currently use ETS because the story is
  about modeling, not storage. A later appendix could show the same domain moved
  onto Postgres with minimal conceptual drift.

Those are worth building. They sit one layer past the boundary this repository
is holding first.

## Tooling

The repo is pinned with `.tool-versions` so the chapters run against an
asdf-managed Elixir and Erlang toolchain that matches the Ash versions used
here.

If `mix` is not available in your shell, configure your asdf shims first rather
than prefixing each command manually.

For the Livebook companions, use the repo-root helper scripts:

```bash
./scripts/install_livebook.sh
./scripts/livebook.sh server livebooks
```

## Start Here

Begin with [`01_order`](./01_order/README.md).

It opens with the Authority's cleanest possible contract:

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
legal boundary can still be trusted.
