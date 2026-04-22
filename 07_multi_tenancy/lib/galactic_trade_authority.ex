defmodule GalacticTradeAuthority do
  @moduledoc """
  Chapter 7 helper API for the Galactic Trade Authority series.

  This chapter keeps the full chapter 6 ledger and makes it tenant-aware:

  - each sector runs the same Authority domain in an isolated tenant
  - manifests, contracts, reports, and audits only exist inside their sector
  - the same manifest number can appear in two sectors without colliding
  - investigative reads must now name which bureaucracy they are querying
  """

  alias GalacticTradeAuthority.{
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
  @primary_tenant "sol"
  @secondary_tenant "perseus"
  @tenants [@primary_tenant, @secondary_tenant]

  @doc """
  Clears the ETS-backed lesson state for every chapter 7 tenant.
  """
  def reset! do
    Enum.each(@resources, fn resource ->
      Enum.each(@tenants, fn tenant ->
        Ash.read!(resource, authorize?: false, tenant: tenant)
        |> Enum.each(&Ash.destroy!(&1, authorize?: false, tenant: tenant))

        # Each tenant owns its own ETS table, so stop both the tenant table and
        # the root table to keep reruns deterministic inside one BEAM session.
        Ash.DataLayer.Ets.stop(resource, tenant)
      end)

      Ash.DataLayer.Ets.stop(resource)
    end)
  end

  @doc """
  Builds two isolated tenant registries from the chapter 6 snapshot.
  """
  def bootstrap_registry! do
    reset!()

    primary = bootstrap_tenant_registry!(@primary_tenant, primary_profile())
    secondary = bootstrap_tenant_registry!(@secondary_tenant, secondary_profile())

    %{
      primary_tenant: @primary_tenant,
      secondary_tenant: @secondary_tenant,
      primary: primary,
      secondary: secondary
    }
  end

  @doc """
  Returns the manifests visible to the given actor inside the specified tenant.
  """
  def visible_manifests!(actor, tenant) do
    actor = assert_actor_in_tenant!(actor, tenant)
    Shipment.list!(actor: actor, tenant: tenant)
  end

  @doc """
  Registers a shipment inside a tenant and records the audit event there.
  """
  def register_shipment!(action, attrs, actor, tenant) when action in @shipment_actions do
    actor = assert_actor_in_tenant!(actor, tenant)
    shipment = apply(Shipment, :"#{action}!", [attrs, [actor: actor, tenant: tenant]])

    AuditRecord.record!(
      %{
        audit_code: next_audit_code!(tenant),
        event_type: :shipment_registered,
        finding: :approved,
        subject_manifest: shipment.manifest_number,
        summary: shipment_summary(shipment, actor),
        recorded_at: DateTime.utc_now(),
        actor_id: actor.id,
        shipment_id: shipment.id
      },
      tenant: tenant
    )

    shipment
  end

  @doc """
  Records a shadow report and its audit event inside one tenant.
  """
  def record_shadow_report!(attrs, actor, tenant) do
    actor = assert_actor_in_tenant!(actor, tenant)
    report = ShadowReport.record!(attrs, tenant: tenant)
    subject_manifest = report_subject_manifest(report, tenant)

    AuditRecord.record!(
      %{
        audit_code: next_audit_code!(tenant),
        event_type: :shadow_report_recorded,
        finding: finding_for_report(report),
        subject_manifest: subject_manifest,
        summary: report_summary(report, actor, subject_manifest),
        recorded_at: DateTime.utc_now(),
        actor_id: actor.id,
        shadow_report_id: report.id,
        shipment_id: report.shipment_id
      },
      tenant: tenant
    )

    report
  end

  @doc """
  Records an explicit authority review on an official shipment inside one tenant.
  """
  def record_override_review!(shipment, actor, summary, tenant) do
    actor = assert_actor_in_tenant!(actor, tenant)

    AuditRecord.record!(
      %{
        audit_code: next_audit_code!(tenant),
        event_type: :override_reviewed,
        finding: :approved,
        subject_manifest: shipment.manifest_number,
        summary: summary,
        recorded_at: DateTime.utc_now(),
        actor_id: actor.id,
        shipment_id: shipment.id
      },
      tenant: tenant
    )
  end

  @doc """
  Returns the audit timeline for a manifest inside one tenant.
  """
  def audit_trail_for_manifest!(manifest, tenant) do
    AuditRecord.list!(tenant: tenant)
    |> Enum.filter(&(&1.subject_manifest == manifest))
    |> Enum.sort_by(fn record ->
      {DateTime.to_unix(record.recorded_at, :microsecond), record.audit_code}
    end)
    |> Enum.map(&timeline_entry(&1, tenant))
  end

  @doc """
  Builds a derived case file for one manifest inside one tenant.
  """
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

  defp bootstrap_tenant_registry!(tenant, profile) do
    authority_actor =
      Trader.register!(
        %{
          callsign: profile.authority_callsign,
          faction: :authority,
          reputation: 95,
          status: :registered,
          override_clearance: true
        },
        tenant: tenant
      )

    investigator_actor =
      Trader.register!(
        %{
          callsign: profile.investigator_callsign,
          faction: :authority,
          reputation: 88,
          status: :registered,
          override_clearance: true
        },
        tenant: tenant
      )

    guild_actor =
      Trader.register!(
        %{
          callsign: profile.guild_callsign,
          faction: :guild,
          reputation: 81,
          status: :registered,
          override_clearance: false
        },
        tenant: tenant
      )

    guild_peer =
      Trader.register!(
        %{
          callsign: profile.guild_peer_callsign,
          faction: :guild,
          reputation: 74,
          status: :registered,
          override_clearance: false
        },
        tenant: tenant
      )

    syndicate_actor =
      Trader.register!(
        %{
          callsign: profile.syndicate_callsign,
          faction: :syndicate,
          reputation: 66,
          status: :registered,
          override_clearance: true
        },
        tenant: tenant
      )

    suspended_actor =
      Trader.register!(
        %{
          callsign: profile.suspended_callsign,
          faction: :guild,
          reputation: 12,
          status: :suspended,
          override_clearance: false
        },
        tenant: tenant
      )

    tax_planet = Planet.register!(profile.tax_planet, tenant: tenant)
    origin_planet = Planet.register!(profile.origin_planet, tenant: tenant)
    restricted_planet = Planet.register!(profile.restricted_planet, tenant: tenant)
    shadow_planet = Planet.register!(profile.shadow_planet, tenant: tenant)

    taxed_resource =
      TradeResource.register!(
        %{
          name: "water",
          category: :essential,
          base_unit: "kiloliter",
          legal_status: :legal
        },
        tenant: tenant
      )

    untaxed_resource =
      TradeResource.register!(
        %{
          name: "grain",
          category: :essential,
          base_unit: "ton",
          legal_status: :legal
        },
        tenant: tenant
      )

    restricted_resource =
      TradeResource.register!(
        %{
          name: "prototype_drives",
          category: :restricted,
          base_unit: "crate",
          legal_status: :restricted
        },
        tenant: tenant
      )

    shadow_resource =
      TradeResource.register!(
        %{
          name: "ghost_chips",
          category: :restricted,
          base_unit: "crate",
          legal_status: :restricted
        },
        tenant: tenant
      )

    origin_water_export_tax =
      PlanetRule.register!(
        %{
          direction: :export,
          effect: :tax,
          tax_rate: profile.export_tax_rate,
          rationale: profile.export_tax_rationale,
          planet_id: origin_planet.id,
          resource_id: taxed_resource.id
        },
        tenant: tenant
      )

    tax_planet_water_import_tax =
      PlanetRule.register!(
        %{
          direction: :import,
          effect: :tax,
          tax_rate: profile.import_tax_rate,
          rationale: profile.import_tax_rationale,
          planet_id: tax_planet.id,
          resource_id: taxed_resource.id
        },
        tenant: tenant
      )

    restricted_import_ban =
      PlanetRule.register!(
        %{
          direction: :import,
          effect: :ban,
          rationale: profile.restricted_ban_rationale,
          planet_id: restricted_planet.id,
          resource_id: restricted_resource.id
        },
        tenant: tenant
      )

    water_exemption =
      Contract.register!(
        %{
          contract_code: "C-EXEMPT-100",
          override_type: :tax_exemption,
          rationale: profile.water_exemption_rationale,
          trader_id: guild_actor.id,
          resource_id: taxed_resource.id,
          destination_planet_id: tax_planet.id
        },
        tenant: tenant
      )

    restricted_permit =
      Contract.register!(
        %{
          contract_code: "C-PERMIT-200",
          override_type: :restricted_permit,
          rationale: profile.restricted_permit_rationale,
          trader_id: syndicate_actor.id,
          resource_id: restricted_resource.id,
          destination_planet_id: restricted_planet.id
        },
        tenant: tenant
      )

    standard_water_shipment =
      register_shipment!(
        :register_standard,
        %{
          manifest_number: "GTA-4001",
          quantity: 40,
          declared_value: 10_000,
          trader_id: guild_actor.id,
          origin_planet_id: origin_planet.id,
          destination_planet_id: tax_planet.id,
          resource_id: taxed_resource.id
        },
        guild_actor,
        tenant
      )

    peer_civil_shipment =
      register_shipment!(
        :register_standard,
        %{
          manifest_number: "GTA-4002",
          quantity: 12,
          declared_value: 4_500,
          trader_id: guild_peer.id,
          origin_planet_id: tax_planet.id,
          destination_planet_id: origin_planet.id,
          resource_id: untaxed_resource.id
        },
        guild_peer,
        tenant
      )

    exempt_water_shipment =
      register_shipment!(
        :register_standard_with_contract,
        %{
          manifest_number: "GTA-4003",
          quantity: 40,
          declared_value: 10_000,
          trader_id: guild_actor.id,
          origin_planet_id: origin_planet.id,
          destination_planet_id: tax_planet.id,
          resource_id: taxed_resource.id,
          contract_id: water_exemption.id
        },
        guild_actor,
        tenant
      )

    permitted_restricted_shipment =
      register_shipment!(
        :register_restricted_with_contract,
        %{
          manifest_number: "GTA-4004",
          quantity: 6,
          declared_value: 16_000,
          trader_id: syndicate_actor.id,
          origin_planet_id: origin_planet.id,
          destination_planet_id: restricted_planet.id,
          resource_id: restricted_resource.id,
          contract_id: restricted_permit.id
        },
        syndicate_actor,
        tenant
      )

    override_review =
      record_override_review!(
        permitted_restricted_shipment,
        authority_actor,
        profile.override_review_summary,
        tenant
      )

    unmatched_report =
      record_shadow_report!(
        %{
          report_number: "SR-5001",
          source_type: :sensor,
          reported_manifest: "GTA-5999",
          resource_id: shadow_resource.id,
          destination_planet_id: shadow_planet.id,
          notes: "Dock scan found cargo containers absent from the public ledger."
        },
        investigator_actor,
        tenant
      )

    matched_report =
      record_shadow_report!(
        %{
          report_number: "SR-5002",
          source_type: :dock_inspector,
          reported_manifest: standard_water_shipment.manifest_number,
          trader_id: guild_actor.id,
          resource_id: taxed_resource.id,
          origin_planet_id: origin_planet.id,
          destination_planet_id: tax_planet.id,
          reported_quantity: 40
        },
        investigator_actor,
        tenant
      )

    contradicted_report =
      record_shadow_report!(
        %{
          report_number: "SR-5003",
          source_type: :seizure,
          reported_manifest: permitted_restricted_shipment.manifest_number,
          trader_id: syndicate_actor.id,
          resource_id: shadow_resource.id,
          origin_planet_id: origin_planet.id,
          destination_planet_id: restricted_planet.id,
          notes:
            "Seizure audit found ghost chips inside a container registered as prototype drives."
        },
        investigator_actor,
        tenant
      )

    case_file = case_file_for_manifest!(permitted_restricted_shipment.manifest_number, tenant)

    %{
      tenant: tenant,
      authority_actor: authority_actor,
      investigator_actor: investigator_actor,
      guild_actor: guild_actor,
      guild_peer: guild_peer,
      syndicate_actor: syndicate_actor,
      suspended_actor: suspended_actor,
      origin_planet: origin_planet,
      tax_planet: tax_planet,
      restricted_planet: restricted_planet,
      shadow_planet: shadow_planet,
      taxed_resource: taxed_resource,
      untaxed_resource: untaxed_resource,
      restricted_resource: restricted_resource,
      shadow_resource: shadow_resource,
      applied_rules: [
        origin_water_export_tax,
        tax_planet_water_import_tax,
        restricted_import_ban
      ],
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
      audit_trail:
        audit_trail_for_manifest!(permitted_restricted_shipment.manifest_number, tenant),
      case_file: case_file
    }
  end

  defp next_audit_code!(tenant) do
    count = AuditRecord.list!(tenant: tenant) |> Enum.count()
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

  defp report_summary(report, actor, subject_manifest) do
    case report.ledger_status do
      :matched ->
        "#{actor.callsign} recorded evidence confirming manifest #{subject_manifest}."

      :unmatched ->
        manifest = subject_manifest || "an unknown manifest"
        "#{actor.callsign} recorded evidence for #{manifest} with no official shipment match."

      :contradicted ->
        "#{actor.callsign} recorded contradictory evidence against manifest #{subject_manifest}."
    end
  end

  defp timeline_entry(record, tenant) do
    actor = find_trader!(tenant, record.actor_id)

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

  defp reports_for_manifest(manifest, shipment_id, tenant) do
    ShadowReport.list!(tenant: tenant)
    |> Enum.filter(fn report ->
      report.reported_manifest == manifest or report.shipment_id == shipment_id
    end)
    |> Enum.sort_by(& &1.report_number)
  end

  defp find_shipment_by_manifest!(manifest, tenant) do
    case Enum.find(
           Shipment.list!(actor: authority_actor!(tenant), tenant: tenant),
           &(&1.manifest_number == manifest)
         ) do
      nil -> raise ArgumentError, "unknown manifest #{manifest} in tenant #{tenant}"
      shipment -> shipment
    end
  end

  defp find_trader!(tenant, trader_id) do
    case Enum.find(Ash.read!(Trader, authorize?: false, tenant: tenant), &(&1.id == trader_id)) do
      nil -> raise ArgumentError, "unknown trader #{trader_id} in tenant #{tenant}"
      trader -> trader
    end
  end

  defp assert_actor_in_tenant!(actor, tenant) do
    case Enum.find(Ash.read!(Trader, authorize?: false, tenant: tenant), &(&1.id == actor.id)) do
      nil ->
        raise ArgumentError, "actor #{actor.callsign} is not registered in tenant #{tenant}"

      tenant_actor ->
        tenant_actor
    end
  end

  defp report_subject_manifest(%{shipment_id: shipment_id}, tenant) when is_binary(shipment_id) do
    find_shipment_in_tenant(tenant, fn shipment -> shipment.id == shipment_id end)
    |> case do
      nil -> nil
      shipment -> shipment.manifest_number
    end
  end

  defp report_subject_manifest(%{reported_manifest: manifest}, _tenant) when is_binary(manifest),
    do: manifest

  defp report_subject_manifest(_report, _tenant), do: nil

  defp authority_actor!(tenant) do
    # The lesson seeds exactly one inspector per tenant and uses that actor for
    # authority-scoped investigative reads.
    Ash.read!(Trader, authorize?: false, tenant: tenant)
    |> Enum.find(&(&1.faction == :authority and String.starts_with?(&1.callsign, "INSPECTOR-")))
  end

  defp find_shipment_in_tenant(tenant, predicate) do
    Ash.read!(Shipment, authorize?: false, tenant: tenant)
    |> Enum.find(predicate)
  end

  defp primary_profile do
    %{
      authority_callsign: "INSPECTOR-IX",
      investigator_callsign: "AUDITOR-12",
      guild_callsign: "MARS-CARRIER",
      guild_peer_callsign: "DUST-COURIER",
      syndicate_callsign: "SHADOW-BROKER",
      suspended_callsign: "GROUNDED-17",
      origin_planet: %{name: "Titan", sector: "Outer Ring", customs_index: 3},
      tax_planet: %{name: "Mars", sector: "Inner Belt", customs_index: 4},
      restricted_planet: %{name: "Europa", sector: "Jovian Reach", customs_index: 5},
      shadow_planet: %{name: "Callisto", sector: "Jovian Reach", customs_index: 2},
      export_tax_rate: 2,
      export_tax_rationale: "Titan ice extraction duty",
      import_tax_rate: 8,
      import_tax_rationale: "Mars aquifer restoration levy",
      restricted_ban_rationale: "Europa propulsion embargo",
      water_exemption_rationale: "Emergency desalination relief",
      restricted_permit_rationale: "Prototype propulsion field trial",
      override_review_summary:
        "Inspector IX approved contract C-PERMIT-200 for manifest GTA-4004."
    }
  end

  defp secondary_profile do
    %{
      authority_callsign: "INSPECTOR-KAPPA",
      investigator_callsign: "AUDITOR-88",
      guild_callsign: "RIM-CARRIER",
      guild_peer_callsign: "RIM-COURIER",
      syndicate_callsign: "NIGHT-BROKER",
      suspended_callsign: "DOCKED-21",
      origin_planet: %{name: "Ganymede", sector: "Perseus Gate", customs_index: 3},
      tax_planet: %{name: "Ceres", sector: "Perseus Gate", customs_index: 4},
      restricted_planet: %{name: "Triton", sector: "Perseus Rim", customs_index: 5},
      shadow_planet: %{name: "Oberon", sector: "Perseus Rim", customs_index: 2},
      export_tax_rate: 1,
      export_tax_rationale: "Ganymede extraction tariff",
      import_tax_rate: 5,
      import_tax_rationale: "Ceres reservoir restoration levy",
      restricted_ban_rationale: "Triton propulsion quarantine",
      water_exemption_rationale: "Perseus desalination relief compact",
      restricted_permit_rationale: "Outer rim propulsion field license",
      override_review_summary:
        "Inspector Kappa approved contract C-PERMIT-200 for manifest GTA-4004."
    }
  end
end
