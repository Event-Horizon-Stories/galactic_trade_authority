defmodule GalacticTradeAuthority do
  @moduledoc """
  Chapter 1 helper API for the Galactic Trade Authority series.

  This chapter keeps the world simple:

  - traders are globally registered
  - planets follow one shared trade rulebook
  - resources are uniformly legal
  - shipments either pass validation or legally never existed
  """

  alias GalacticTradeAuthority.Resources.{Planet, Shipment, TradeResource, Trader}

  @resources [Shipment, TradeResource, Planet, Trader]

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
  Builds the minimal chapter 1 world and registers one valid shipment.
  """
  def bootstrap_registry! do
    reset!()

    trader =
      Trader.register!(%{
        callsign: "ORBITAL-3",
        faction: :guild,
        reputation: 72,
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

    water =
      TradeResource.register!(%{
        name: "water",
        category: :essential,
        base_unit: "kiloliter",
        legal_status: :legal
      })

    shipment =
      Shipment.register!(%{
        manifest_number: "GTA-1001",
        quantity: 40,
        declared_value: 9_500,
        trader_id: trader.id,
        origin_planet_id: mars.id,
        destination_planet_id: titan.id,
        resource_id: water.id
      })

    %{
      trader: trader,
      origin_planet: mars,
      destination_planet: titan,
      resource: water,
      shipment: shipment
    }
  end

  @doc """
  Returns all registered shipments in the chapter 1 registry.
  """
  def list_shipments! do
    Shipment.list!()
  end

  @doc """
  Returns a resource list paired with their lesson-facing labels.
  """
  def resources do
    [
      trader: Trader,
      planet: Planet,
      trade_resource: TradeResource,
      shipment: Shipment
    ]
  end
end
