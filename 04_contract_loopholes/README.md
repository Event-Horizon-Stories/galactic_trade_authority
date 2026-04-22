# Lesson 04: Contractual Loopholes

The Galactic Trade Authority can already enforce route law and faction power.

That still is not enough.

Power in a bureaucracy does not only appear as rank. It also appears as paper:
special permits, tax exemptions, privileged supply agreements, emergency waivers.

This chapter introduces the next collapse in the model:

the normal rule is no longer the final rule.

Contracts become formal override instruments that can do two dangerous things:

- make an otherwise restricted shipment legal
- change the financial truth attached to a legal shipment

Interactive companion: [`../livebooks/04_contract_loopholes.livemd`](../livebooks/04_contract_loopholes.livemd)

## What You'll Learn

By the end of this lesson, you should understand:

- how to model negotiated exceptions as their own Ash resource
- how one create action can evaluate normal rule outcomes plus override documents
- how calculations and changes can derive the final official record
- why explicit override state is safer than scattering special cases through code
- how Ash starts to carry layered business rules without collapsing into conditionals

## The Story

The GTA still claims the law is sovereign.

Reality now reveals the usual loophole:

- a trader has a contract exempting water shipments from Mars import levy
- a syndicate operator carries a special permit for restricted prototype drives
- a manifest that should have failed now passes because a document says it may
- the final shipment record must preserve both the rule and the exception

The Authority does not admit this as corruption. It calls it authorized exception.

## The Ash Concept

Chapter 3 taught actor-based power.

Chapter 4 teaches negotiated override logic.

The core modeling move is a new resource:

- `ContractLoopholes.Contract`

That contract belongs to a trader and targets a cargo profile. The shipment action
then reads the route, the cargo, and any matching contract before deciding the
final result.

The important shift is that the shipment action now has layers:

1. ordinary route rules
2. contract overrides
3. derived official result

That is why this chapter leans on action logic and derived values instead of only
resource-level validation.

## What We're Building

We will create:

- a `Contract` resource for override agreements
- a shipment action that evaluates route restrictions and matching contracts
- derived financial and legal fields that explain how the final record was reached

The chapter 4 override model includes:

- a Mars water tax exemption contract
- a prototype-drive permit contract
- shipments that remain ordinary when no matching contract exists

## The Code

The lesson implementation lives in:

- [`lib/contract_loopholes/registry.ex`](./lib/contract_loopholes/registry.ex)
- [`lib/contract_loopholes/trader.ex`](./lib/contract_loopholes/trader.ex)
- [`lib/contract_loopholes/planet.ex`](./lib/contract_loopholes/planet.ex)
- [`lib/contract_loopholes/trade_resource.ex`](./lib/contract_loopholes/trade_resource.ex)
- [`lib/contract_loopholes/planet_rule.ex`](./lib/contract_loopholes/planet_rule.ex)
- [`lib/contract_loopholes/contract.ex`](./lib/contract_loopholes/contract.ex)
- [`lib/contract_loopholes/shipment.ex`](./lib/contract_loopholes/shipment.ex)
- [`lib/contract_loopholes/rule_engine.ex`](./lib/contract_loopholes/rule_engine.ex)
- [`lib/contract_loopholes.ex`](./lib/contract_loopholes.ex)

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

  change ContractLoopholes.Changes.ApplyRegulatoryOutcome
end
```

That action no longer just decides valid versus invalid. It computes what the law
became after the contract was allowed into the room.

The new exception layer is explicit in its own resource:

```elixir
attributes do
  uuid_primary_key :id
  attribute :contract_code, :string, allow_nil?: false
  attribute :override_type, :atom, allow_nil?: false,
    constraints: [one_of: [:tax_exemption, :restricted_permit]]
  attribute :rationale, :string, allow_nil?: false
end

relationships do
  belongs_to :trader, ContractLoopholes.Trader, allow_nil?: false
  belongs_to :resource, ContractLoopholes.TradeResource, allow_nil?: false
  belongs_to :destination_planet, ContractLoopholes.Planet, allow_nil?: false
end
```

That is the main modeling choice in chapter 4. Exceptions are not scattered
conditionals. They are official documents the system can query, test, and cite
when the default legal outcome no longer wins.

## Trying It Out

Run the lesson:

```bash
cd 04_contract_loopholes
mix deps.get
mix test
```

You can also inspect the chapter in `iex`:

```bash
cd 04_contract_loopholes
iex -S mix
```

Then try:

```elixir
state = ContractLoopholes.bootstrap_registry!()

%{
  taxed_without_contract: state.standard_water_shipment.tax_due,
  waived_with_contract: state.exempt_water_shipment.tax_due,
  permitted_status: state.permitted_restricted_shipment.route_decision,
  override_summary: state.permitted_restricted_shipment.override_summary
}
```

## What the Tests Prove

The lesson tests in [`test/contract_loopholes_test.exs`](./test/contract_loopholes_test.exs) prove four things:

- standard water shipments still pay Mars import tax
- a matching exemption contract zeroes out that tax
- a restricted shipment can become legal through a permit contract
- a restricted shipment without a matching contract is rejected

Those results matter because the ledger now has to preserve not just the baseline
law, but the reason the baseline law stopped winning.

## Why This Matters

This is the chapter where the model stops pretending exceptions are edge cases.

The GTA now has to answer:

- which rule would have applied normally?
- which contract matched this shipment?
- what part of the normal outcome was changed?
- how should the final ledger explain that deviation?

That is layered rule evaluation, not form validation.

## Ash Takeaway

Ash works well when one action becomes the point where multiple business layers
meet. Explicit resources for exception documents are better than hidden ad hoc
conditionals because they keep the override visible, queryable, and testable.

## What the Authority Can Do Now

The GTA can now:

- store formal override documents as first-class resources
- compute tax exemptions from matching contracts
- legalize restricted cargo through explicit permits
- record how and why an override changed the final shipment outcome

## What Still Hurts

The system now knows how to represent official exceptions, but it still assumes
the ledger is complete.

The next problem is worse: shipments, evidence, and rumors that never entered the
official system at all.

## Next Lesson

Lesson 5 will introduce off-ledger behavior.
