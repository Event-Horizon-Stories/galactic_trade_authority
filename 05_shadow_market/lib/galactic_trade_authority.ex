defmodule GalacticTradeAuthority do
  @moduledoc """
  Chapter 5 helper API for the Galactic Trade Authority series.

  This chapter keeps the official ledger intact while adding off-ledger evidence:

  - actor policies still shape who can register or read shipments
  - route rules still exist
  - contracts can override tax and restriction outcomes
  - shadow reports can describe events the official system never fully captured
  """

  alias GalacticTradeAuthority.Resources.{
    Contract,
    Planet,
    PlanetRule,
    ShadowReport,
    Shipment,
    TradeResource,
    Trader
  }

  @resources [ShadowReport, Shipment, Contract, PlanetRule, TradeResource, Planet, Trader]

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
  Builds the chapter 5 registry, official ledger, and shadow evidence.
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
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-4001",
          quantity: 40,
          declared_value: 10_000,
          trader_id: guild_actor.id,
          origin_planet_id: titan.id,
          destination_planet_id: mars.id,
          resource_id: water.id
        },
        actor: guild_actor
      )

    peer_civil_shipment =
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-4002",
          quantity: 12,
          declared_value: 4_500,
          trader_id: guild_peer.id,
          origin_planet_id: mars.id,
          destination_planet_id: titan.id,
          resource_id: grain.id
        },
        actor: guild_peer
      )

    exempt_water_shipment =
      Shipment.register_standard_with_contract!(
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
        actor: guild_actor
      )

    permitted_restricted_shipment =
      Shipment.register_restricted_with_contract!(
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
        actor: syndicate_actor
      )

    unmatched_report =
      ShadowReport.record!(%{
        report_number: "SR-5001",
        source_type: :sensor,
        reported_manifest: "GTA-5999",
        resource_id: ghost_chips.id,
        destination_planet_id: callisto.id,
        notes: "Dock scan found cargo containers absent from the public ledger."
      })

    matched_report =
      ShadowReport.record!(%{
        report_number: "SR-5002",
        source_type: :dock_inspector,
        reported_manifest: standard_water_shipment.manifest_number,
        trader_id: guild_actor.id,
        resource_id: water.id,
        origin_planet_id: titan.id,
        destination_planet_id: mars.id,
        reported_quantity: 40
      })

    contradicted_report =
      ShadowReport.record!(%{
        report_number: "SR-5003",
        source_type: :informant,
        reported_manifest: standard_water_shipment.manifest_number,
        trader_id: guild_actor.id,
        resource_id: ghost_chips.id,
        origin_planet_id: titan.id,
        destination_planet_id: mars.id,
        notes: "Witness claims the sealed pallets held ghost chips, not water."
      })

    %{
      authority_actor: authority_actor,
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
      standard_water_shipment: standard_water_shipment,
      peer_civil_shipment: peer_civil_shipment,
      exempt_water_shipment: exempt_water_shipment,
      permitted_restricted_shipment: permitted_restricted_shipment,
      unmatched_report: unmatched_report,
      matched_report: matched_report,
      contradicted_report: contradicted_report
    }
  end

  @doc """
  Returns the manifests visible to the given actor.
  """
  def visible_manifests!(actor) do
    Shipment.list!(actor: actor)
  end
end
