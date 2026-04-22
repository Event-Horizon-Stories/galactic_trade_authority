# Lesson 05: Shadow Market

The Galactic Trade Authority now has strict rules, local law, faction power, and
documented loopholes.

That still assumes the ledger is complete.

It is not.

This chapter introduces the next collapse in the model:

the system can only validate what reaches the system.

The shadow market lives in everything that was seen, seized, rumored, scanned,
or reported without ever becoming an official shipment.

Interactive companion: [`../livebooks/05_shadow_market.livemd`](../livebooks/05_shadow_market.livemd)

## What You'll Learn

By the end of this lesson, you should understand:

- how to keep the official ledger strict while adding a parallel evidence model
- how optional relationships let you store partial truth without corrupting core resources
- how soft constraints differ from legal constraints
- how one create action can classify evidence as matched, unmatched, or contradictory
- why Ash still helps when the data is incomplete

## The Story

The GTA insists that invalid shipments do not exist.

Reality answers with a quieter problem:

- a dock scan sees containers tied to no official manifest
- an inspector records a shipment that does match the ledger
- an informant claims the manifest exists, but the cargo is different
- the Authority needs to preserve these reports without granting them the status of law

This is not the official truth log yet.

It is the pressure building around the official truth.

## The Ash Concept

Earlier chapters taught the GTA how to say yes, no, or exception.

Chapter 5 teaches the system how to say:

- we saw something
- we cannot fully prove it
- we still need to keep the record

The key modeling move is a new resource:

- `ShadowMarket.ShadowReport`

That report may point to an official shipment, but it does not require one. It
can be partial, contradictory, and still worth storing.

The official shipment resource stays strict:

- complete relationships
- hard validation
- no off-ledger shortcuts

The shadow report resource is different:

- optional relationships
- one required structured lead
- derived ledger classification

## What We're Building

We will create:

- a strict `Shipment` resource for the official ledger
- a `ShadowReport` resource for off-ledger evidence
- a matcher that classifies reports as `:matched`, `:unmatched`, or `:contradicted`

The chapter 5 registry includes:

- one official water shipment
- one unmatched report for a manifest the ledger does not know
- one matched report that reconciles cleanly to the official shipment
- one contradictory report that points to the shipment but disputes its cargo

## The Code

The lesson implementation lives in:

- [`lib/shadow_market/registry.ex`](./lib/shadow_market/registry.ex)
- [`lib/shadow_market/trader.ex`](./lib/shadow_market/trader.ex)
- [`lib/shadow_market/planet.ex`](./lib/shadow_market/planet.ex)
- [`lib/shadow_market/trade_resource.ex`](./lib/shadow_market/trade_resource.ex)
- [`lib/shadow_market/shipment.ex`](./lib/shadow_market/shipment.ex)
- [`lib/shadow_market/shadow_report.ex`](./lib/shadow_market/shadow_report.ex)
- [`lib/shadow_market/ledger_matcher.ex`](./lib/shadow_market/ledger_matcher.ex)
- [`lib/shadow_market/changes/classify_ledger_presence.ex`](./lib/shadow_market/changes/classify_ledger_presence.ex)
- [`lib/shadow_market/validations/require_structured_lead.ex`](./lib/shadow_market/validations/require_structured_lead.ex)
- [`lib/shadow_market.ex`](./lib/shadow_market.ex)

The `ShadowReport` action is the center of the chapter:

```elixir
create :record do
  primary? true

  accept [
    :report_number,
    :source_type,
    :reported_manifest,
    :reported_quantity,
    :notes,
    :shipment_id,
    :trader_id,
    :resource_id,
    :origin_planet_id,
    :destination_planet_id
  ]

  validate match(:report_number, ~r/^SR-\d{4}$/)
  validate ShadowMarket.Validations.RequireStructuredLead
  change ShadowMarket.Changes.ClassifyLedgerPresence
end
```

That action never upgrades evidence into law. It only decides how the evidence
relates to the law the GTA already recorded.

The classification work happens in a dedicated matcher instead of inside the
resource definition:

```elixir
def classify(params) do
  case find_shipment(params) do
    nil ->
      %{
        ledger_status: :unmatched,
        shipment_id: nil,
        report_summary: unmatched_summary(params)
      }

    shipment ->
      case mismatches(params, shipment) do
        [] ->
          %{
            ledger_status: :matched,
            shipment_id: shipment.id,
            report_summary: "matched official shipment #{shipment.manifest_number}"
          }

        fields ->
          %{
            ledger_status: :contradicted,
            shipment_id: shipment.id,
            report_summary:
              "matched official shipment #{shipment.manifest_number} but conflicts on #{Enum.join(fields, ", ")}"
          }
      end
  end
end
```

That split is the chapter 5 point. The official shipment model stays strict,
while the parallel evidence model gets its own softer interpretation layer.

## Trying It Out

Run the lesson:

```bash
cd 05_shadow_market
mix deps.get
mix test
```

You can also inspect the chapter in `iex`:

```bash
cd 05_shadow_market
iex -S mix
```

Then try:

```elixir
state = ShadowMarket.bootstrap_registry!()

%{
  official_manifest: state.official_shipment.manifest_number,
  unmatched_status: state.unmatched_report.ledger_status,
  matched_status: state.matched_report.ledger_status,
  contradicted_summary: state.contradicted_report.report_summary
}
```

## What the Tests Prove

The lesson tests in [`test/shadow_market_test.exs`](./test/shadow_market_test.exs) prove four things:

- off-ledger evidence can exist without any official shipment match
- evidence can reconcile to an official shipment without mutating the shipment
- contradictory evidence is preserved and flagged instead of discarded
- even a soft evidence model still needs one structured lead

Those results matter because the GTA must now track uncertainty without lying
about certainty.

## Why This Matters

This is the chapter where the ledger stops being the whole world.

The Authority now has to answer:

- what did we officially approve?
- what did we merely observe?
- what evidence points to missing or false paperwork?
- how do we preserve suspicion without promoting it to fact?

That is the difference between validation and evidence handling.

## Ash Takeaway

Ash is still useful when the domain is messy, but the lesson is not to make every
resource permissive. The stronger move is to isolate imperfect truth in its own
resource with explicit soft constraints and explicit classification.

## What the Authority Can Do Now

The GTA can now:

- keep official shipments strict and legally complete
- store off-ledger evidence with partial context
- reconcile reports to known shipments when possible
- preserve contradictions instead of erasing them

## What Still Hurts

The system can now store suspicious evidence, but it still cannot explain who
approved the official record, who ignored the warning, or how responsibility
traveled through the bureaucracy.

## Next Lesson

Lesson 6 will introduce investigation and traceability.
