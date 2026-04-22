# Lesson 02: Planetary Law

The Galactic Trade Authority's first model worked only because the universe lied
for it.

Now the lie breaks.

Mars taxes imported water. Europa bans imported AI chips. Titan charges export
fees on ice shipments. The manifest alone is no longer enough. A shipment now has
to survive its route.

This chapter introduces the first collapse of the clean registry from lesson 1.
Global rules are no longer sufficient because the law depends on where goods come
from and where they are going.

Interactive companion: [`../livebooks/02_planetary_law.livemd`](../livebooks/02_planetary_law.livemd)

## What You'll Learn

By the end of this lesson, you should understand:

- how Ash relationships let local rules point at planets and resources
- how custom validations can reject shipments based on related domain state
- how custom changes can rewrite accepted shipments with calculated legal effects
- why the same shipment can be legal on one route and impossible on another
- how Ash starts to feel necessary once rules depend on context

## The Story

The Authority still wants one official ledger.

Reality now resists that simplicity:

- planets set import and export rules
- some routes add taxes
- some routes forbid goods outright
- the same cargo can be ordinary on one route and contraband on another

The GTA responds the only way it knows how: it turns local law into system law.

## The Ash Concept

Chapter 1 taught the registry.

Chapter 2 teaches route-aware legality.

The core modeling move is a new resource:

- `GalacticTradeAuthority.Resources.PlanetRule`

That resource belongs to:

- a `Planet`
- a `TradeResource`

The `Shipment` action then consults those relationships in two stages:

- a validation rejects banned routes
- a change applies route taxes and annotates the resulting shipment

That split matters.

Some local rules make a shipment impossible. Others keep the shipment legal but
change the official financial truth recorded about it.

## What We're Building

We will create:

- a `PlanetRule` resource for local import/export law
- a shipment validation that rejects locally banned routes
- a shipment change that computes route taxes and compliance summaries

The chapter 2 rule set includes:

- Titan export tax on water
- Mars import tax on water
- Europa import ban on AI chips

That lets one resource reveal three different legal outcomes:

- taxed at origin
- taxed at destination
- banned entirely

## The Code

The lesson implementation lives in:

- [`lib/galactic_trade_authority/registry.ex`](./lib/galactic_trade_authority/registry.ex)
- [`lib/galactic_trade_authority/resources/trader.ex`](./lib/galactic_trade_authority/resources/trader.ex)
- [`lib/galactic_trade_authority/resources/planet.ex`](./lib/galactic_trade_authority/resources/planet.ex)
- [`lib/galactic_trade_authority/resources/trade_resource.ex`](./lib/galactic_trade_authority/resources/trade_resource.ex)
- [`lib/galactic_trade_authority/resources/planet_rule.ex`](./lib/galactic_trade_authority/resources/planet_rule.ex)
- [`lib/galactic_trade_authority/resources/shipment.ex`](./lib/galactic_trade_authority/resources/shipment.ex)
- [`lib/galactic_trade_authority/rules/local_rules.ex`](./lib/galactic_trade_authority/rules/local_rules.ex)
- [`lib/galactic_trade_authority/validations/allowed_by_planetary_law.ex`](./lib/galactic_trade_authority/validations/allowed_by_planetary_law.ex)
- [`lib/galactic_trade_authority/changes/apply_transit_controls.ex`](./lib/galactic_trade_authority/changes/apply_transit_controls.ex)

The `Shipment` action is the center of the chapter:

```elixir
create :register do
  primary? true

  accept [
    :manifest_number,
    :quantity,
    :declared_value,
    :trader_id,
    :origin_planet_id,
    :destination_planet_id,
    :resource_id
  ]

  validate match(:manifest_number, ~r/^GTA-\d{4}$/)
  validate compare(:quantity, greater_than: 0)
  validate compare(:declared_value, greater_than_or_equal_to: 0)
  validate {GalacticTradeAuthority.Validations.DistinctRoute,
            left: :origin_planet_id, right: :destination_planet_id}
  validate GalacticTradeAuthority.Validations.AllowedByPlanetaryLaw

  change GalacticTradeAuthority.Changes.ApplyTransitControls
end
```

That one action now does more than gate raw input. It interprets the route.

The new legal pressure lives in `PlanetRule`:

```elixir
attributes do
  uuid_primary_key :id
  attribute :direction, :atom, allow_nil?: false, constraints: [one_of: [:import, :export]]
  attribute :effect, :atom, allow_nil?: false, constraints: [one_of: [:tax, :ban]]
  attribute :tax_rate, :integer
  attribute :rationale, :string, allow_nil?: false
end

relationships do
  belongs_to :planet, GalacticTradeAuthority.Resources.Planet, allow_nil?: false
  belongs_to :resource, GalacticTradeAuthority.Resources.TradeResource, allow_nil?: false
end
```

That resource is what breaks chapter 1. The law no longer lives only on the
shipment itself. It now depends on related records the Authority has to consult
before declaring a manifest real.

## Trying It Out

Run the lesson:

```bash
cd 02_planetary_law
mix deps.get
mix test
```

You can also inspect the chapter in `iex`:

```bash
cd 02_planetary_law
iex -S mix
```

Then try:

```elixir
state = GalacticTradeAuthority.bootstrap_registry!()

%{
  manifest: state.shipment.manifest_number,
  route: {state.origin_planet.name, state.destination_planet.name},
  tax_due: state.shipment.tax_due,
  classification: state.shipment.route_classification,
  rules: Enum.map(state.applied_rules, & &1.rationale)
}
```

## What the Tests Prove

The lesson tests in [`test/galactic_trade_authority_test.exs`](./test/galactic_trade_authority_test.exs) prove four things:

- a taxed water shipment is accepted and rewritten with local duties
- an AI chip shipment into Europa is rejected
- a route with no local rules stays unchanged
- the registry can explain which rules applied to a shipment

Those results matter because the official record is no longer a raw copy of the
manifest. It is the manifest after local law has distorted it.

## Why This Matters

This is the first chapter where legality becomes contextual.

The GTA now has to answer:

- which planet is judging this shipment?
- is the rule about import or export?
- is the shipment still legal if it survives?
- if it survives, what new cost becomes official truth?

Once those questions appear, the lesson stops being CRUD.

## Ash Takeaway

Ash gets sharper when one action can combine:

- direct input validation
- related-resource lookup
- domain-specific rejection
- domain-specific mutation

Chapter 2 is the first time the registry behaves like a law engine instead of a
typed form handler.

## What the Authority Can Do Now

The GTA can now:

- record local trade law as its own resource
- reject banned shipments based on their route
- calculate route-specific taxes on accepted shipments
- preserve the distinction between impossible shipments and merely expensive ones

## What Still Hurts

The model still treats every actor the same.

A guild trader, an Authority inspector, and a syndicate proxy still hit the same
rules in the same way. The moment power starts changing what different actors can
see or do, chapter 2 stops being enough.

## Next Lesson

Lesson 3 will introduce faction power.
