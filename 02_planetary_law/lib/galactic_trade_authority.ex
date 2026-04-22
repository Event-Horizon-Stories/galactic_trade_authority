defmodule GalacticTradeAuthority do
  @moduledoc """
  Chapter 2 helper API for the Galactic Trade Authority series.

  This chapter turns a clean registry into a route-aware legal system:

  - planets can publish import and export rules
  - shipments can be taxed differently by origin and destination
  - banned routes are rejected before they become official truth
  """

  alias GalacticTradeAuthority.Resources.{Planet, PlanetRule, Shipment, TradeResource, Trader}

  @resources [Shipment, PlanetRule, TradeResource, Planet, Trader]

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
  Builds the chapter 2 registry, local laws, and one taxed shipment.
  """
  def bootstrap_registry! do
    reset!()

    trader =
      Trader.register!(%{
        callsign: "DUST-RUNNER",
        faction: :guild,
        reputation: 81,
        status: :registered
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

    ai_chips =
      TradeResource.register!(%{
        name: "ai_chips",
        category: :industrial,
        base_unit: "crate",
        legal_status: :legal
      })

    grain =
      TradeResource.register!(%{
        name: "grain",
        category: :essential,
        base_unit: "ton",
        legal_status: :legal
      })

    titan_export_water =
      PlanetRule.register!(%{
        direction: :export,
        effect: :tax,
        tax_rate: 2,
        rationale: "Titan ice extraction duty",
        planet_id: titan.id,
        resource_id: water.id
      })

    mars_import_water =
      PlanetRule.register!(%{
        direction: :import,
        effect: :tax,
        tax_rate: 8,
        rationale: "Mars aquifer restoration levy",
        planet_id: mars.id,
        resource_id: water.id
      })

    europa_import_ai_ban =
      PlanetRule.register!(%{
        direction: :import,
        effect: :ban,
        rationale: "Europa sentient systems moratorium",
        planet_id: europa.id,
        resource_id: ai_chips.id
      })

    shipment =
      Shipment.register!(%{
        manifest_number: "GTA-2001",
        quantity: 25,
        declared_value: 10_000,
        trader_id: trader.id,
        origin_planet_id: titan.id,
        destination_planet_id: mars.id,
        resource_id: water.id
      })

    %{
      trader: trader,
      origin_planet: titan,
      destination_planet: mars,
      blocked_planet: europa,
      taxed_resource: water,
      blocked_resource: ai_chips,
      untaxed_resource: grain,
      shipment: shipment,
      applied_rules: [titan_export_water, mars_import_water],
      blocked_rule: europa_import_ai_ban
    }
  end

  @doc """
  Returns all registered shipments in the chapter 2 registry.
  """
  def list_shipments! do
    Shipment.list!()
  end
end
