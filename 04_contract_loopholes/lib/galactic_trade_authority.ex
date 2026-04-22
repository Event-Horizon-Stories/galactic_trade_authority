defmodule GalacticTradeAuthority do
  @moduledoc """
  Chapter 4 helper API for the Galactic Trade Authority series.

  This chapter turns a political legal system into layered exception handling:

  - actor policies still shape who can register or read shipments
  - route rules still exist
  - contracts can override tax and restriction outcomes
  - the final shipment record preserves both the rule and the loophole
  """

  alias GalacticTradeAuthority.Resources.{
    Contract,
    Planet,
    PlanetRule,
    Shipment,
    TradeResource,
    Trader
  }

  @resources [Shipment, Contract, PlanetRule, TradeResource, Planet, Trader]

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
  Builds the chapter 4 registry, contracts, actors, and representative outcomes.
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

    %{
      authority_actor: authority_actor,
      guild_actor: guild_actor,
      guild_peer: guild_peer,
      syndicate_actor: syndicate_actor,
      suspended_actor: suspended_actor,
      origin_planet: titan,
      tax_planet: mars,
      restricted_planet: europa,
      taxed_resource: water,
      untaxed_resource: grain,
      restricted_resource: prototype_drives,
      applied_rules: [titan_water_export_tax, mars_water_import_tax, europa_drive_ban],
      contracts: [water_exemption, restricted_permit],
      standard_water_shipment: standard_water_shipment,
      peer_civil_shipment: peer_civil_shipment,
      exempt_water_shipment: exempt_water_shipment,
      permitted_restricted_shipment: permitted_restricted_shipment
    }
  end

  @doc """
  Returns the manifests visible to the given actor.
  """
  def visible_manifests!(actor) do
    Shipment.list!(actor: actor)
  end
end
