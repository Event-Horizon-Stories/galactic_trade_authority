# Lesson 01: Order

The Galactic Trade Authority begins with a clean lie.

Everything is globally consistent. Traders register once. Planets obey one trade
rulebook. Resources are either legal or not. Shipments pass validation and become
official, or they fail validation and legally never existed.

For now, the registry still believes one lawbook is enough. Nothing local has
started resisting it yet.

Interactive companion: [`../livebooks/01_order.livemd`](../livebooks/01_order.livemd)

## What Changes

- how to define Ash resources on one domain
- how resource attributes become the official shape of data
- how create actions form the approved entry points into the system
- how validations make legal state explicit
- why a rejected changeset is part of the domain story, not just a form error

## The Story

The GTA has one job in chapter 1: define the official registry.

Right now the Authority believes four things:

- every trader can be globally registered
- every planet follows the same rules
- every resource has one shared legal status
- every shipment can be judged from its own manifest alone

That belief is stable for exactly one chapter.

## Under The Hood

Ash is the law engine here.

The domain names the things that exist. Each resource declares the public data
shape for one political object. Each create action is a sanctioned way for new
state to enter the registry. Validations are where the Authority draws the line
between real and impossible.

At this stage, the Authority is built from:

- `GalacticTradeAuthority.Resources.Trader`
- `GalacticTradeAuthority.Resources.Planet`
- `GalacticTradeAuthority.Resources.TradeResource`
- `GalacticTradeAuthority.Resources.Shipment`

All four resources live in the same `GalacticTradeAuthority.Registry` domain.

## Authority Changes

The Authority adds:

- a `Trader` resource for registered operators
- a `Planet` resource for official destinations
- a `TradeResource` resource for legal goods
- a `Shipment` resource for manifest registration

The shipment action enforces the chapter 1 trade rules:

- manifest numbers must look like `GTA-1234`
- quantity must be greater than zero
- declared value cannot be negative
- origin and destination cannot be the same planet

If a shipment fails those rules, it is legally considered never to have existed.

## The Code

The implementation lives in:

- [`lib/galactic_trade_authority/registry.ex`](./lib/galactic_trade_authority/registry.ex)
- [`lib/galactic_trade_authority/resources/trader.ex`](./lib/galactic_trade_authority/resources/trader.ex)
- [`lib/galactic_trade_authority/resources/planet.ex`](./lib/galactic_trade_authority/resources/planet.ex)
- [`lib/galactic_trade_authority/resources/trade_resource.ex`](./lib/galactic_trade_authority/resources/trade_resource.ex)
- [`lib/galactic_trade_authority/resources/shipment.ex`](./lib/galactic_trade_authority/resources/shipment.ex)
- [`lib/galactic_trade_authority.ex`](./lib/galactic_trade_authority.ex)

The `Shipment` resource is the center of the chapter:

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
end
```

That one action is the first GTA border checkpoint. It decides whether a manifest
becomes official truth or disappears at the boundary.

The registry remains compact:

```elixir
defmodule GalacticTradeAuthority.Registry do
  use Ash.Domain

  resources do
    resource(GalacticTradeAuthority.Resources.Trader)
    resource(GalacticTradeAuthority.Resources.Planet)
    resource(GalacticTradeAuthority.Resources.TradeResource)
    resource(GalacticTradeAuthority.Resources.Shipment)
  end
end
```

That matters because the first Ash move here is to name the official objects,
then make legal entry points explicit.

## Trying It Out

Run the chapter:

```bash
cd 01_order
mix deps.get
mix test
```

You can also inspect it in `iex`:

```bash
cd 01_order
iex -S mix
```

Then try:

```elixir
state = GalacticTradeAuthority.bootstrap_registry!()

%{
  trader: state.trader.callsign,
  route: {state.origin_planet.name, state.destination_planet.name},
  manifest: state.shipment.manifest_number,
  shipments: Enum.count(GalacticTradeAuthority.list_shipments!())
}
```

## What the Tests Prove

The tests in [`test/galactic_trade_authority_test.exs`](./test/galactic_trade_authority_test.exs) prove four things:

- the registry can create a valid official shipment
- malformed manifest numbers are rejected
- non-positive quantities are rejected
- identical origin and destination planets are rejected

Those failures matter because the system is not just storing data. It is deciding
what counts as a legal event.

## Why This Matters

The opening model is deliberately naive.

It assumes:

- law is global
- legality is uniform
- actor identity does not change the rules
- the manifest contains enough truth on its own

That is what makes the model easy to understand. It is also what makes the next
chapter inevitable.

## What Holds

Ash works best when the domain needs a visible boundary between allowed and
disallowed state. Here, that boundary is still simple enough to trust at a glance.

## What the Authority Can Do Now

The GTA can now:

- register traders
- register planets
- register trade goods
- register shipments through one official action
- reject invalid manifests before they become legal truth

## What Still Hurts

The model only works while the law is universal.

The moment Mars taxes water differently from Titan, or Europa bans a category of
goods that everyone else allows, chapter 1 collapses.

## Next Shift

Next, planetary law arrives.
