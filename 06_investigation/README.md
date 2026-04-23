# Lesson 06: Investigation

The Galactic Trade Authority now has strict rules, local law, faction power,
documented loopholes, and off-ledger evidence.

That still is not enough.

The system can now tell you that something looks wrong.

It still cannot tell you who made it official.

The next collapse is simple: the ledger needs memory, not just validation.

Interactive companion: [`../livebooks/06_investigation.livemd`](../livebooks/06_investigation.livemd)

## What Changes

- how to model audit history as its own Ash resource
- how to keep official actions and investigative evidence on the same timeline
- how derived case views can turn raw records into traceable responsibility
- why "who approved it?" is a domain question, not a logging afterthought
- how Ash helps once the problem becomes history and blame instead of input validation

## The Story

The GTA already knows how to reject bad manifests and preserve contradictory
evidence.

Now a worse question arrives:

- a contract-permitted shipment passes into Europa
- a later seizure suggests the cargo was not what the permit allowed
- the system has the shipment
- the system has the contradiction
- the system still needs to answer who made the shipment official

That is the chapter 6 pressure.

Truth is no longer enough.

Responsibility has to be reconstructable.

## Under The Hood

The GTA already knows how to preserve imperfect truth beside the official
ledger. Now it has to preserve institutional memory about that truth.

The key modeling move is a new resource:

- `GalacticTradeAuthority.Resources.AuditRecord`

That resource does not replace shipments or shadow reports. It connects them.

The chapter also adds a derived case-file view that reads the official shipment,
the later evidence, and the audit trail together.

That split matters:

- resources preserve the events
- the case file explains the events

## Authority Changes

The Authority adds:

- the full official ledger from chapter 5
- a new `AuditRecord` resource for who registered, reviewed, or flagged a manifest
- helper flows that record audit history when shipments and reports are created
- a derived case file that answers who approved a manifest and who later challenged it

The chapter 6 registry includes:

- the same official shipments, contracts, and shadow reports from chapter 5
- an authority review on the contract-permitted restricted shipment
- an audit trail for `GTA-4004`
- a case file that names both the approver and the later investigator

## The Code

The implementation lives in:

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

The new `AuditRecord` resource is the center of the chapter:

```elixir
create :record do
  primary?(true)

  accept([
    :audit_code,
    :event_type,
    :finding,
    :subject_manifest,
    :summary,
    :recorded_at,
    :actor_id,
    :shipment_id,
    :shadow_report_id
  ])
end
```

That action gives the Authority an explicit place to store institutional memory
instead of leaving it in logs, comments, or implied control flow.

The derived case view then turns raw history into something investigable:

```elixir
def case_file_for_manifest!(manifest) do
  shipment = find_shipment_by_manifest!(manifest)
  reports = reports_for_manifest(manifest, shipment.id)
  timeline = audit_trail_for_manifest!(manifest)

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

That is the point in one function: raw events matter, but readers need derived
views when the question becomes blame.

## Trying It Out

Run the chapter:

```bash
cd 06_investigation
mix deps.get
mix test
```

You can also inspect it in `iex`:

```bash
cd 06_investigation
iex -S mix
```

Then try:

```elixir
state = GalacticTradeAuthority.bootstrap_registry!()

%{
  manifest: state.case_file.manifest,
  approved_by: state.case_file.approved_by,
  flagged_by: state.case_file.flagged_by,
  timeline: Enum.map(state.case_file.timeline, &{&1.event_type, &1.actor})
}
```

## What the Tests Prove

The tests in [`test/galactic_trade_authority_test.exs`](./test/galactic_trade_authority_test.exs) prove eight things:

- chapter 5 tax and contract behavior still works
- faction-based shipment visibility still works
- audit records preserve who registered a manifest
- authority review becomes part of the same timeline
- contradictory evidence becomes traceable instead of isolated
- a derived case file can explain approval and escalation together
- unmatched evidence still creates a usable audit trail
- suspended actors still cannot create official shipments

Those results matter because the GTA is no longer just deciding legality. It is
deciding accountability.

## Why This Matters

This is the chapter where the ledger becomes answerable to time.

The Authority now has to answer:

- who registered this manifest?
- who reviewed the override?
- who later challenged the record?
- what order did those decisions happen in?

That is not just state validation anymore.

It is institutional history.

## What Holds

Ash remains useful when the domain shifts from "is this allowed?" to "how did we
get here?" Explicit history resources and derived case views keep responsibility
queryable instead of burying it in logs or side effects.

## What the Authority Can Do Now

The GTA can now:

- keep the full chapter 5 official ledger intact
- record who registered, reviewed, or challenged a manifest
- preserve one timeline across official and off-ledger events
- build a case file from raw audit history
- answer who approved a bad outcome and who later exposed it

## What Still Hurts

The system can now explain one bureaucracy.

It still assumes there is only one bureaucracy.

The next pressure is scale: multiple sectors, multiple legal environments, and
the same Authority engine running in isolated tenants.

## Next Shift

In [`07_multi_tenancy`](../07_multi_tenancy/README.md), the same bureaucracy has to run in more than one sector.
