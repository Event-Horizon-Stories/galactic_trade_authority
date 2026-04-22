defmodule ContractLoopholes do
  @moduledoc """
  Chapter 4 helper API for the Galactic Trade Authority series.

  This chapter turns ordinary rule processing into layered exception handling:

  - route rules still exist
  - contracts can override tax and restriction outcomes
  - the final shipment record preserves both the rule and the loophole
  """

  alias ContractLoopholes.{Contract, Planet, PlanetRule, Shipment, TradeResource, Trader}

  @resources [Shipment, Contract, PlanetRule, TradeResource, Planet, Trader]

  @doc """
  Clears ETS-backed lesson state so each example or test starts from a known registry.
  """
  def reset! do
    Enum.each(@resources, fn resource ->
      resource.list!()
      |> Enum.each(&Ash.destroy!/1)

      Ash.DataLayer.Ets.stop(resource)
    end)
  end

  @doc """
  Builds the chapter 4 registry, contracts, and representative shipment outcomes.
  """
  def bootstrap_registry! do
    reset!()

    trader =
      Trader.register!(%{
        callsign: "MARS-CARRIER",
        faction: :guild
      })

    mars =
      Planet.register!(%{
        name: "Mars",
        sector: "Inner Belt"
      })

    titan =
      Planet.register!(%{
        name: "Titan",
        sector: "Outer Ring"
      })

    europa =
      Planet.register!(%{
        name: "Europa",
        sector: "Jovian Reach"
      })

    water =
      TradeResource.register!(%{
        name: "water",
        category: :essential
      })

    prototype_drives =
      TradeResource.register!(%{
        name: "prototype_drives",
        category: :restricted
      })

    mars_water_tax =
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
        trader_id: trader.id,
        resource_id: water.id,
        destination_planet_id: mars.id
      })

    restricted_permit =
      Contract.register!(%{
        contract_code: "C-PERMIT-200",
        override_type: :restricted_permit,
        rationale: "Prototype propulsion field trial",
        trader_id: trader.id,
        resource_id: prototype_drives.id,
        destination_planet_id: europa.id
      })

    standard_water_shipment =
      Shipment.register!(%{
        manifest_number: "GTA-4001",
        quantity: 40,
        declared_value: 10_000,
        trader_id: trader.id,
        origin_planet_id: titan.id,
        destination_planet_id: mars.id,
        resource_id: water.id
      })

    exempt_water_shipment =
      Shipment.register_with_contract!(%{
        manifest_number: "GTA-4002",
        quantity: 40,
        declared_value: 10_000,
        trader_id: trader.id,
        origin_planet_id: titan.id,
        destination_planet_id: mars.id,
        resource_id: water.id,
        contract_id: water_exemption.id
      })

    permitted_restricted_shipment =
      Shipment.register_with_contract!(%{
        manifest_number: "GTA-4003",
        quantity: 6,
        declared_value: 16_000,
        trader_id: trader.id,
        origin_planet_id: titan.id,
        destination_planet_id: europa.id,
        resource_id: prototype_drives.id,
        contract_id: restricted_permit.id
      })

    %{
      trader: trader,
      origin_planet: titan,
      tax_planet: mars,
      restricted_planet: europa,
      taxed_resource: water,
      restricted_resource: prototype_drives,
      applied_rules: [mars_water_tax, europa_drive_ban],
      contracts: [water_exemption, restricted_permit],
      standard_water_shipment: standard_water_shipment,
      exempt_water_shipment: exempt_water_shipment,
      permitted_restricted_shipment: permitted_restricted_shipment
    }
  end
end
