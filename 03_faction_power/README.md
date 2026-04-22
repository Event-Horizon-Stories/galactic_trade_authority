# Lesson 03: Faction Power

The Galactic Trade Authority already knows how to apply law.

Now it has to admit a worse truth:

the law is not applied by abstract routes alone. It is applied by people with
rank, faction, leverage, and exceptions.

Guild traders can work the civil lanes. Syndicate brokers can touch restricted
cargo only when someone has granted them quiet clearance. Authority inspectors
can see everything because they are the ones defining what "everything" means.

This chapter shifts the pressure from route-aware validation to actor-aware
authorization. The same shipment is no longer equally visible or creatable for
everyone.

Interactive companion: [`../livebooks/03_faction_power.livemd`](../livebooks/03_faction_power.livemd)

## What You'll Learn

By the end of this lesson, you should understand:

- how to add Ash authorization to a resource with `Ash.Policy.Authorizer`
- how policy checks can gate create actions based on the actor
- how read policies filter visible records instead of only raising errors
- how a bypass policy models institutional power
- why authorization is part of domain behavior, not just an API wrapper concern

## The Story

The GTA’s official position is that all traders operate under the same ledger.

Reality is uglier:

- Authority inspectors can read sealed manifests
- guild traders can move routine cargo but not shadow-lane records
- syndicate brokers sometimes get restricted access through override clearance
- suspended traders are still in the database, but the system should stop
  trusting them

At this stage the law depends on who is acting, not only on what is being moved.

## The Ash Concept

Chapter 2 taught local law.

Chapter 3 teaches actor-dependent power.

The core modeling move is that `GalacticTradeAuthority.Resources.Shipment` now has an authorizer and
resource policies, while the chapter 2 route-law resources stay in place. Those
policies do two different jobs:

- decide who may create standard or restricted manifests
- decide which existing manifests a given actor is allowed to see

That second point matters because read authorization in Ash can filter records.
The system does not just say "forbidden." It can present each faction with a
different slice of the official truth.

## What We're Building

We will create:

- a `Trader` resource that also serves as the lesson actor model
- the same `Planet`, `TradeResource`, and `PlanetRule` resources from chapter 2
- a `Shipment` resource that still applies route law before authorization
- shipment policies for authority, guild, syndicate, and suspended actors

The chapter 3 power model is:

- Authority inspectors bypass all normal shipment policies
- guild traders can create standard manifests tied to themselves
- syndicate traders need `override_clearance` to create restricted manifests
- read visibility changes by faction

## The Code

The lesson implementation lives in:

- [`lib/galactic_trade_authority/registry.ex`](./lib/galactic_trade_authority/registry.ex)
- [`lib/galactic_trade_authority/resources/trader.ex`](./lib/galactic_trade_authority/resources/trader.ex)
- [`lib/galactic_trade_authority/resources/planet.ex`](./lib/galactic_trade_authority/resources/planet.ex)
- [`lib/galactic_trade_authority/resources/trade_resource.ex`](./lib/galactic_trade_authority/resources/trade_resource.ex)
- [`lib/galactic_trade_authority/resources/planet_rule.ex`](./lib/galactic_trade_authority/resources/planet_rule.ex)
- [`lib/galactic_trade_authority/rules/local_rules.ex`](./lib/galactic_trade_authority/rules/local_rules.ex)
- [`lib/galactic_trade_authority/resources/shipment.ex`](./lib/galactic_trade_authority/resources/shipment.ex)
- [`lib/galactic_trade_authority.ex`](./lib/galactic_trade_authority.ex)

The `Shipment` resource is the center of the chapter:

```elixir
use Ash.Resource,
  domain: GalacticTradeAuthority.Registry,
  data_layer: Ash.DataLayer.Ets,
  authorizers: [Ash.Policy.Authorizer]
```

It then defines policies that read like institutional rules:

```elixir
policies do
  bypass actor_attribute_equals(:faction, :authority) do
    authorize_if always()
  end

  policy action(:register_standard) do
    forbid_unless actor_attribute_equals(:status, :registered)
    forbid_unless relating_to_actor(:trader)
    authorize_if actor_attribute_equals(:faction, :guild)
    authorize_if actor_attribute_equals(:faction, :syndicate)
  end
end
```

The policy code is the domain story here. It is the point where legal truth bends
around power.

Read visibility is just as important as create authorization:

```elixir
policy [
  action_type(:read),
  actor_attribute_equals(:status, :registered),
  actor_attribute_equals(:faction, :guild)
] do
  authorize_if(expr(trader_id == ^actor(:id) or corridor == :civil))
end
```

That is the chapter 3 shift in one block: the ledger is no longer one neutral
window. The resource decides which slice of official truth each actor is allowed
to receive.

## Trying It Out

Run the lesson:

```bash
cd 03_faction_power
mix deps.get
mix test
```

You can also inspect the chapter in `iex`:

```bash
cd 03_faction_power
iex -S mix
```

Then try:

```elixir
state = GalacticTradeAuthority.bootstrap_registry!()

%{
  authority_view:
    Enum.map(GalacticTradeAuthority.visible_manifests!(state.authority_actor), & &1.manifest_number),
  guild_view:
    Enum.map(GalacticTradeAuthority.visible_manifests!(state.guild_actor), & &1.manifest_number),
  syndicate_view:
    Enum.map(GalacticTradeAuthority.visible_manifests!(state.syndicate_actor), & &1.manifest_number)
}
```

## What the Tests Prove

The lesson tests in [`test/galactic_trade_authority_test.exs`](./test/galactic_trade_authority_test.exs) prove six things:

- chapter 2 tax handling still works for legal routed cargo
- authority actors can see all manifests
- guild actors only see civil manifests plus their own
- cleared syndicate actors can create restricted manifests
- planetary bans still reject illegal routes before they become records
- suspended actors cannot read or create shipment records

Those outcomes matter because the official ledger is no longer one neutral window.
It is a controlled projection shaped by who is looking at it.

## Why This Matters

This is the chapter where the system stops pretending that all users meet the law
from the same position.

The GTA now has to answer:

- who is allowed to create this record?
- who is allowed to read it later?
- when does institutional rank bypass the ordinary rule path?
- how much truth should each faction receive?

Once those questions appear, authorization is part of the model itself.

## Ash Takeaway

Ash policies let authorization live with the resource instead of floating above it
in controllers, service objects, or hand-rolled conditionals. That matters when
permission itself is part of the domain story.

## What the Authority Can Do Now

The GTA can now:

- treat traders as actors with faction and status
- keep route-law enforcement from chapter 2 in the same shipment model
- authorize create actions differently by actor type
- filter read results by faction visibility
- model institutional bypass explicitly

## What Still Hurts

The system can now say who has power, but it still cannot say why one contract,
permit, or exemption should override a normal rule.

That next layer is not about actor identity alone. It is about negotiated
exceptions.

## Next Lesson

Lesson 4 will introduce contractual loopholes.
