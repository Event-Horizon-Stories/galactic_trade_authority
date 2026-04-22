# Lesson 07: The Authority Crosses Sectors

The Galactic Trade Authority now has strict rules, local law, faction power,
documented loopholes, off-ledger evidence, and a traceable audit trail.

That still is not enough.

The system can now explain one bureaucracy.

It still assumes there is only one bureaucracy.

In this lesson, we keep the full investigation-era ledger and make it operate
across isolated sectors.

Interactive companion: [`../livebooks/07_multi_tenancy.livemd`](../livebooks/07_multi_tenancy.livemd)

## What You'll Learn

By the end of this lesson, you should understand:

- how to apply Ash multitenancy with `strategy(:context)`
- how tenant-scoped reads and writes keep identical manifests from colliding
- how to thread tenant context through rule evaluation and investigation helpers
- why multi-sector isolation is a domain rule, not just an infrastructure detail
- how Ash makes "which bureaucracy are we in?" an explicit part of the API

## The Story

The GTA already knows how to reject bad manifests, preserve contradictory
evidence, and reconstruct responsibility.

Now scale arrives:

- the Sol sector runs its own registry
- the Perseus sector runs the same registry
- both sectors may issue the same manifest numbers
- both sectors may use the same contract codes
- investigators still need answers without reading the wrong sector's truth

That is the chapter 7 pressure.

The law engine still works.

The assumption of one global ledger does not.

## The Ash Concept

Chapter 6 taught the GTA how to explain one official history.

Chapter 7 teaches the system how to repeat that same history shape in multiple
isolated places.

The key modeling move is multitenancy on every official resource:

- `GalacticTradeAuthority.Resources.Trader`
- `GalacticTradeAuthority.Resources.Planet`
- `GalacticTradeAuthority.Resources.TradeResource`
- `GalacticTradeAuthority.Resources.PlanetRule`
- `GalacticTradeAuthority.Resources.Contract`
- `GalacticTradeAuthority.Resources.Shipment`
- `GalacticTradeAuthority.Resources.ShadowReport`
- `GalacticTradeAuthority.Resources.AuditRecord`

The helper API also changes. Registration, investigative reads, and case-file
queries now require a tenant so the caller has to name which bureaucracy they
mean.

## What We're Building

We will create:

- the full chapter 6 ledger from the previous lesson
- multitenant Ash resources using context-based tenancy
- a two-sector bootstrap that seeds identical manifest numbers in isolated ledgers
- tenant-aware helper functions for visibility, shadow reporting, and case-file reads

The chapter 7 registry includes:

- a `sol` tenant with the original lesson profile
- a `perseus` tenant with a different rule surface
- the same manifest number `GTA-4004` in both sectors
- separate audit timelines and case files for each sector

## The Code

The lesson implementation lives in:

- [`lib/galactic_trade_authority/registry.ex`](./lib/galactic_trade_authority/registry.ex)
- [`lib/galactic_trade_authority/resources/trader.ex`](./lib/galactic_trade_authority/resources/trader.ex)
- [`lib/galactic_trade_authority/resources/planet.ex`](./lib/galactic_trade_authority/resources/planet.ex)
- [`lib/galactic_trade_authority/resources/trade_resource.ex`](./lib/galactic_trade_authority/resources/trade_resource.ex)
- [`lib/galactic_trade_authority/resources/planet_rule.ex`](./lib/galactic_trade_authority/resources/planet_rule.ex)
- [`lib/galactic_trade_authority/resources/contract.ex`](./lib/galactic_trade_authority/resources/contract.ex)
- [`lib/galactic_trade_authority/resources/shipment.ex`](./lib/galactic_trade_authority/resources/shipment.ex)
- [`lib/galactic_trade_authority/resources/shadow_report.ex`](./lib/galactic_trade_authority/resources/shadow_report.ex)
- [`lib/galactic_trade_authority/resources/audit_record.ex`](./lib/galactic_trade_authority/resources/audit_record.ex)
- [`lib/galactic_trade_authority/rules/rule_engine.ex`](./lib/galactic_trade_authority/rules/rule_engine.ex)
- [`lib/galactic_trade_authority/investigations/ledger_matcher.ex`](./lib/galactic_trade_authority/investigations/ledger_matcher.ex)
- [`lib/galactic_trade_authority/changes/apply_regulatory_outcome.ex`](./lib/galactic_trade_authority/changes/apply_regulatory_outcome.ex)
- [`lib/galactic_trade_authority/changes/classify_ledger_presence.ex`](./lib/galactic_trade_authority/changes/classify_ledger_presence.ex)
- [`lib/galactic_trade_authority/validations/distinct_route.ex`](./lib/galactic_trade_authority/validations/distinct_route.ex)
- [`lib/galactic_trade_authority/validations/require_structured_lead.ex`](./lib/galactic_trade_authority/validations/require_structured_lead.ex)
- [`lib/galactic_trade_authority.ex`](./lib/galactic_trade_authority.ex)

The new chapter-wide center is the multitenancy declaration on each resource:

```elixir
use Ash.Resource,
  domain: GalacticTradeAuthority.Registry,
  data_layer: Ash.DataLayer.Ets

multitenancy do
  strategy(:context)
end
```

That DSL change means the resource only exists inside a named tenant context.

The helper API then makes that context impossible to ignore:

```elixir
def case_file_for_manifest!(manifest, tenant) do
  shipment = find_shipment_by_manifest!(manifest, tenant)
  reports = reports_for_manifest(manifest, shipment.id, tenant)
  timeline = audit_trail_for_manifest!(manifest, tenant)

  %{
    manifest: manifest,
    shipment: shipment,
    reports: reports,
    approved_by: approver_for_timeline(timeline),
    flagged_by: flagger_for_timeline(timeline),
    timeline: timeline
  }
end
```

That is the chapter 7 point in one function: even investigation helpers must say
which Authority instance they are querying.

The bootstrap also shows why this matters:

```elixir
def bootstrap_registry! do
  reset!()

  primary = bootstrap_tenant_registry!("sol", primary_profile())
  secondary = bootstrap_tenant_registry!("perseus", secondary_profile())

  %{
    primary_tenant: "sol",
    secondary_tenant: "perseus",
    primary: primary,
    secondary: secondary
  }
end
```

The sectors share code. They do not share state.

## Trying It Out

Run the lesson:

```bash
cd 07_multi_tenancy
mix deps.get
mix test
```

You can also inspect the chapter in `iex`:

```bash
cd 07_multi_tenancy
iex -S mix
```

Then try:

```elixir
state = GalacticTradeAuthority.bootstrap_registry!()

%{
  sol_manifest: state.primary.standard_water_shipment.manifest_number,
  sol_tax: state.primary.standard_water_shipment.tax_due,
  perseus_manifest: state.secondary.standard_water_shipment.manifest_number,
  perseus_tax: state.secondary.standard_water_shipment.tax_due
}
```

You should see the same manifest number in both sectors with different legal
outcomes.

## What the Tests Prove

The lesson tests in [`test/galactic_trade_authority_test.exs`](./test/galactic_trade_authority_test.exs) prove eight things:

- the chapter 6 official ledger still works inside a tenant
- contract-permitted restricted shipments still survive in a tenant
- faction-based manifest visibility still works inside a tenant
- the same manifest number can exist in more than one sector
- investigative reads stay isolated per tenant
- shipment reads reject calls that omit a tenant
- report validations still run inside a tenant
- suspended actors still cannot create official shipments inside their own sector

Those results matter because the GTA is no longer just deciding legality and
accountability. It is deciding them separately for each bureaucracy it operates.

## Why This Matters

This is the chapter where the ledger becomes answerable to boundaries.

The Authority now has to answer:

- which sector owns this manifest?
- which sector's rules set this tax outcome?
- which investigator flagged this contradiction?
- can identical manifest numbers coexist without leaking across sectors?

That is not just scale.

It is institutional isolation.

## Why We Are Not Using One Shared Ledger

We could model sectors with a plain `sector` attribute and manually thread that
through every read filter.

We are deliberately not doing that here.

This lesson is about teaching that sector identity is part of the resource
contract itself. Ash multitenancy makes that boundary harder to forget and
harder to bypass accidentally.

The story needs that pressure. A hidden sector filter would make the chapter
look simpler than it really is.

## Ash Takeaway

Ash remains useful when the domain shifts from "what is allowed?" and "who
approved it?" to "which isolated bureaucracy owns this reality?" Multitenancy
keeps that question explicit at the framework boundary instead of leaving it as
an application convention.

## What the Authority Can Do Now

The GTA can now:

- run the full chapter 6 law engine in more than one sector
- preserve different taxes and investigators for the same manifest number
- keep reads, reports, and audit trails scoped to the correct tenant
- force callers to name the bureaucracy they are addressing
- scale the same domain model without collapsing sectors into one ledger

## What Still Hurts

The system can now scale the bureaucracy cleanly.

It still lives entirely in memory.

That is fine for a teaching series.

If the Authority needed to survive restarts, expose an API, or coordinate tenant
resolution from incoming requests, the next step would be a persistent data
layer and an external interface.
