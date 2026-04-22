defmodule Investigation do
  @moduledoc """
  Chapter 6 helper API for the Galactic Trade Authority series.

  This chapter keeps the full chapter 5 ledger and adds traceability:

  - official shipments still pass through route rules, policies, and contracts
  - shadow reports still preserve imperfect truth beside the official ledger
  - audit records capture who registered, reviewed, or flagged a manifest
  - derived case files turn raw history into an investigation timeline
  """

  alias Investigation.{
    AuditRecord,
    Contract,
    Planet,
    PlanetRule,
    ShadowReport,
    Shipment,
    TradeResource,
    Trader
  }

  @resources [
    AuditRecord,
    ShadowReport,
    Shipment,
    Contract,
    PlanetRule,
    TradeResource,
    Planet,
    Trader
  ]
  @shipment_actions [
    :register_standard,
    :register_standard_with_contract,
    :register_restricted,
    :register_restricted_with_contract
  ]

  @doc """
  Clears ETS-backed lesson state so each example or test starts from a known registry.
  """
  def reset! do
    Enum.each(@resources, fn resource ->
      Ash.read!(resource, authorize?: false)
      |> Enum.each(&Ash.destroy!(&1, authorize?: false))

      Ash.DataLayer.Ets.stop(resource)
    end)
  end

  @doc """
  Builds the chapter 6 registry, audit trail, and an investigated manifest.
  """
  def bootstrap_registry! do
    reset!()

    authority_actor =
      Trader.register!(%{
        callsign: "INSPECTOR-IX",
        faction: :authority,
        reputation: 95,
        status: :registered,
        override_clearance: true
      })

    investigator_actor =
      Trader.register!(%{
        callsign: "AUDITOR-12",
        faction: :authority,
        reputation: 88,
        status: :registered,
        override_clearance: true
      })

    guild_actor =
      Trader.register!(%{
        callsign: "MARS-CARRIER",
        faction: :guild,
        reputation: 81,
        status: :registered,
        override_clearance: false
      })

    guild_peer =
      Trader.register!(%{
        callsign: "DUST-COURIER",
        faction: :guild,
        reputation: 74,
        status: :registered,
        override_clearance: false
      })

    syndicate_actor =
      Trader.register!(%{
        callsign: "SHADOW-BROKER",
        faction: :syndicate,
        reputation: 66,
        status: :registered,
        override_clearance: true
      })

    suspended_actor =
      Trader.register!(%{
        callsign: "GROUNDED-17",
        faction: :guild,
        reputation: 12,
        status: :suspended,
        override_clearance: false
      })

    mars =
      Planet.register!(%{
        name: "Mars",
        sector: "Inner Belt",
        customs_index: 4
      })

    titan =
      Planet.register!(%{
        name: "Titan",
        sector: "Outer Ring",
        customs_index: 3
      })

    europa =
      Planet.register!(%{
        name: "Europa",
        sector: "Jovian Reach",
        customs_index: 5
      })

    callisto =
      Planet.register!(%{
        name: "Callisto",
        sector: "Jovian Reach",
        customs_index: 2
      })

    water =
      TradeResource.register!(%{
        name: "water",
        category: :essential,
        base_unit: "kiloliter",
        legal_status: :legal
      })

    grain =
      TradeResource.register!(%{
        name: "grain",
        category: :essential,
        base_unit: "ton",
        legal_status: :legal
      })

    prototype_drives =
      TradeResource.register!(%{
        name: "prototype_drives",
        category: :restricted,
        base_unit: "crate",
        legal_status: :restricted
      })

    ghost_chips =
      TradeResource.register!(%{
        name: "ghost_chips",
        category: :restricted,
        base_unit: "crate",
        legal_status: :restricted
      })

    titan_water_export_tax =
      PlanetRule.register!(%{
        direction: :export,
        effect: :tax,
        tax_rate: 2,
        rationale: "Titan ice extraction duty",
        planet_id: titan.id,
        resource_id: water.id
      })

    mars_water_import_tax =
      PlanetRule.register!(%{
        direction: :import,
        effect: :tax,
        tax_rate: 8,
        rationale: "Mars aquifer restoration levy",
        planet_id: mars.id,
        resource_id: water.id
      })

    europa_drive_ban =
      PlanetRule.register!(%{
        direction: :import,
        effect: :ban,
        rationale: "Europa propulsion embargo",
        planet_id: europa.id,
        resource_id: prototype_drives.id
      })

    water_exemption =
      Contract.register!(%{
        contract_code: "C-EXEMPT-100",
        override_type: :tax_exemption,
        rationale: "Emergency desalination relief",
        trader_id: guild_actor.id,
        resource_id: water.id,
        destination_planet_id: mars.id
      })

    restricted_permit =
      Contract.register!(%{
        contract_code: "C-PERMIT-200",
        override_type: :restricted_permit,
        rationale: "Prototype propulsion field trial",
        trader_id: syndicate_actor.id,
        resource_id: prototype_drives.id,
        destination_planet_id: europa.id
      })

    standard_water_shipment =
      register_shipment!(
        :register_standard,
        %{
          manifest_number: "GTA-4001",
          quantity: 40,
          declared_value: 10_000,
          trader_id: guild_actor.id,
          origin_planet_id: titan.id,
          destination_planet_id: mars.id,
          resource_id: water.id
        },
        guild_actor
      )

    peer_civil_shipment =
      register_shipment!(
        :register_standard,
        %{
          manifest_number: "GTA-4002",
          quantity: 12,
          declared_value: 4_500,
          trader_id: guild_peer.id,
          origin_planet_id: mars.id,
          destination_planet_id: titan.id,
          resource_id: grain.id
        },
        guild_peer
      )

    exempt_water_shipment =
      register_shipment!(
        :register_standard_with_contract,
        %{
          manifest_number: "GTA-4003",
          quantity: 40,
          declared_value: 10_000,
          trader_id: guild_actor.id,
          origin_planet_id: titan.id,
          destination_planet_id: mars.id,
          resource_id: water.id,
          contract_id: water_exemption.id
        },
        guild_actor
      )

    permitted_restricted_shipment =
      register_shipment!(
        :register_restricted_with_contract,
        %{
          manifest_number: "GTA-4004",
          quantity: 6,
          declared_value: 16_000,
          trader_id: syndicate_actor.id,
          origin_planet_id: titan.id,
          destination_planet_id: europa.id,
          resource_id: prototype_drives.id,
          contract_id: restricted_permit.id
        },
        syndicate_actor
      )

    override_review =
      record_override_review!(
        permitted_restricted_shipment,
        authority_actor,
        "Inspector IX approved contract C-PERMIT-200 for manifest GTA-4004."
      )

    unmatched_report =
      record_shadow_report!(
        %{
          report_number: "SR-5001",
          source_type: :sensor,
          reported_manifest: "GTA-5999",
          resource_id: ghost_chips.id,
          destination_planet_id: callisto.id,
          notes: "Dock scan found cargo containers absent from the public ledger."
        },
        investigator_actor
      )

    matched_report =
      record_shadow_report!(
        %{
          report_number: "SR-5002",
          source_type: :dock_inspector,
          reported_manifest: standard_water_shipment.manifest_number,
          trader_id: guild_actor.id,
          resource_id: water.id,
          origin_planet_id: titan.id,
          destination_planet_id: mars.id,
          reported_quantity: 40
        },
        investigator_actor
      )

    contradicted_report =
      record_shadow_report!(
        %{
          report_number: "SR-5003",
          source_type: :seizure,
          reported_manifest: permitted_restricted_shipment.manifest_number,
          trader_id: syndicate_actor.id,
          resource_id: ghost_chips.id,
          origin_planet_id: titan.id,
          destination_planet_id: europa.id,
          notes:
            "Seizure audit found ghost chips inside a container registered as prototype drives."
        },
        investigator_actor
      )

    case_file = case_file_for_manifest!(permitted_restricted_shipment.manifest_number)

    %{
      authority_actor: authority_actor,
      investigator_actor: investigator_actor,
      guild_actor: guild_actor,
      guild_peer: guild_peer,
      syndicate_actor: syndicate_actor,
      suspended_actor: suspended_actor,
      origin_planet: titan,
      tax_planet: mars,
      restricted_planet: europa,
      shadow_planet: callisto,
      taxed_resource: water,
      untaxed_resource: grain,
      restricted_resource: prototype_drives,
      shadow_resource: ghost_chips,
      applied_rules: [titan_water_export_tax, mars_water_import_tax, europa_drive_ban],
      contracts: [water_exemption, restricted_permit],
      official_shipment: standard_water_shipment,
      investigated_shipment: permitted_restricted_shipment,
      standard_water_shipment: standard_water_shipment,
      peer_civil_shipment: peer_civil_shipment,
      exempt_water_shipment: exempt_water_shipment,
      permitted_restricted_shipment: permitted_restricted_shipment,
      override_review: override_review,
      unmatched_report: unmatched_report,
      matched_report: matched_report,
      contradicted_report: contradicted_report,
      audit_trail: audit_trail_for_manifest!(permitted_restricted_shipment.manifest_number),
      case_file: case_file
    }
  end

  @doc """
  Returns the manifests visible to the given actor.
  """
  def visible_manifests!(actor) do
    Shipment.list!(actor: actor)
  end

  @doc """
  Registers a shipment through one of the official actions and records the audit event.
  """
  def register_shipment!(action, attrs, actor) when action in @shipment_actions do
    shipment = apply(Shipment, :"#{action}!", [attrs, [actor: actor]])

    AuditRecord.record!(%{
      audit_code: next_audit_code!(),
      event_type: :shipment_registered,
      finding: :approved,
      subject_manifest: shipment.manifest_number,
      summary: shipment_summary(shipment, actor),
      recorded_at: DateTime.utc_now(),
      actor_id: actor.id,
      shipment_id: shipment.id
    })

    shipment
  end

  @doc """
  Records a shadow report and stores the corresponding audit event.
  """
  def record_shadow_report!(attrs, actor) do
    report = ShadowReport.record!(attrs)

    AuditRecord.record!(%{
      audit_code: next_audit_code!(),
      event_type: :shadow_report_recorded,
      finding: finding_for_report(report),
      subject_manifest: report.reported_manifest,
      summary: report_summary(report, actor),
      recorded_at: DateTime.utc_now(),
      actor_id: actor.id,
      shadow_report_id: report.id,
      shipment_id: report.shipment_id
    })

    report
  end

  @doc """
  Records an explicit authority review on an official shipment.
  """
  def record_override_review!(shipment, actor, summary) do
    AuditRecord.record!(%{
      audit_code: next_audit_code!(),
      event_type: :override_reviewed,
      finding: :approved,
      subject_manifest: shipment.manifest_number,
      summary: summary,
      recorded_at: DateTime.utc_now(),
      actor_id: actor.id,
      shipment_id: shipment.id
    })
  end

  @doc """
  Returns the audit timeline for a manifest with actor names resolved.
  """
  def audit_trail_for_manifest!(manifest) do
    AuditRecord.list!()
    |> Enum.filter(&(&1.subject_manifest == manifest))
    |> Enum.sort_by(fn record ->
      {DateTime.to_unix(record.recorded_at, :microsecond), record.audit_code}
    end)
    |> Enum.map(&timeline_entry/1)
  end

  @doc """
  Builds a derived case file for an investigated manifest.
  """
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

  defp next_audit_code! do
    count = AuditRecord.list!() |> Enum.count()
    "AR-#{6_000 + count + 1}"
  end

  defp shipment_summary(shipment, actor) do
    base = "#{actor.callsign} registered manifest #{shipment.manifest_number}"

    case shipment.route_decision do
      :standard ->
        "#{base} under the standard ledger path."

      :tax_exempt ->
        "#{base} with tax exemption #{shipment.override_summary}."

      :permitted_by_contract ->
        "#{base} through override #{shipment.override_summary}."
    end
  end

  defp finding_for_report(report), do: report.ledger_status

  defp report_summary(report, actor) do
    case report.ledger_status do
      :matched ->
        "#{actor.callsign} recorded evidence confirming manifest #{report.reported_manifest}."

      :unmatched ->
        manifest = report.reported_manifest || "an unknown manifest"
        "#{actor.callsign} recorded evidence for #{manifest} with no official shipment match."

      :contradicted ->
        "#{actor.callsign} recorded contradictory evidence against manifest #{report.reported_manifest}."
    end
  end

  defp timeline_entry(record) do
    actor = find_trader!(record.actor_id)

    %{
      audit_code: record.audit_code,
      event_type: record.event_type,
      finding: record.finding,
      actor: actor.callsign,
      summary: record.summary
    }
  end

  defp approver_for_timeline(timeline) do
    override_review =
      Enum.find(timeline, fn entry ->
        entry.event_type == :override_reviewed
      end)

    registration =
      Enum.find(timeline, fn entry ->
        entry.event_type == :shipment_registered
      end)

    case override_review || registration do
      nil -> nil
      entry -> entry.actor
    end
  end

  defp flagger_for_timeline(timeline) do
    case Enum.find(timeline, fn entry -> entry.finding == :contradicted end) do
      nil -> nil
      entry -> entry.actor
    end
  end

  defp reports_for_manifest(manifest, shipment_id) do
    ShadowReport.list!()
    |> Enum.filter(fn report ->
      report.reported_manifest == manifest or report.shipment_id == shipment_id
    end)
    |> Enum.sort_by(& &1.report_number)
  end

  defp find_shipment_by_manifest!(manifest) do
    case Enum.find(Shipment.list!(actor: authority_actor()), &(&1.manifest_number == manifest)) do
      nil -> raise ArgumentError, "unknown manifest #{manifest}"
      shipment -> shipment
    end
  end

  defp find_trader!(trader_id) do
    case Enum.find(Ash.read!(Trader, authorize?: false), &(&1.id == trader_id)) do
      nil -> raise ArgumentError, "unknown trader #{trader_id}"
      trader -> trader
    end
  end

  defp authority_actor do
    Ash.read!(Trader, authorize?: false)
    |> Enum.find(&(&1.faction == :authority and &1.callsign == "INSPECTOR-IX"))
  end
end
