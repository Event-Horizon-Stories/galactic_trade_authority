defmodule ShadowMarket do
  @moduledoc """
  Chapter 5 helper API for the Galactic Trade Authority series.

  This chapter keeps the official ledger strict while introducing evidence that
  the ledger may be incomplete:

  - official shipments still require complete legal data
  - shadow reports can be partial and contradictory
  - the Authority stores both without pretending they are the same truth
  """

  alias ShadowMarket.{Planet, ShadowReport, Shipment, TradeResource, Trader}

  @resources [ShadowReport, Shipment, TradeResource, Planet, Trader]

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
  Builds the chapter 5 registry, one official shipment, and three shadow reports.
  """
  def bootstrap_registry! do
    reset!()

    trader =
      Trader.register!(%{
        callsign: "NIGHT-RUNNER",
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

    callisto =
      Planet.register!(%{
        name: "Callisto",
        sector: "Jovian Reach"
      })

    water =
      TradeResource.register!(%{
        name: "water",
        category: :essential
      })

    ghost_chips =
      TradeResource.register!(%{
        name: "ghost_chips",
        category: :contraband
      })

    official_shipment =
      Shipment.register!(%{
        manifest_number: "GTA-5001",
        quantity: 32,
        declared_value: 8_000,
        trader_id: trader.id,
        origin_planet_id: titan.id,
        destination_planet_id: mars.id,
        resource_id: water.id
      })

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
        reported_manifest: official_shipment.manifest_number,
        trader_id: trader.id,
        resource_id: water.id,
        origin_planet_id: titan.id,
        destination_planet_id: mars.id,
        reported_quantity: 32
      })

    contradicted_report =
      ShadowReport.record!(%{
        report_number: "SR-5003",
        source_type: :informant,
        reported_manifest: official_shipment.manifest_number,
        trader_id: trader.id,
        resource_id: ghost_chips.id,
        origin_planet_id: titan.id,
        destination_planet_id: mars.id,
        notes: "Witness claims the sealed pallets held ghost chips, not water."
      })

    %{
      trader: trader,
      origin_planet: titan,
      destination_planet: mars,
      shadow_destination: callisto,
      official_resource: water,
      shadow_resource: ghost_chips,
      official_shipment: official_shipment,
      unmatched_report: unmatched_report,
      matched_report: matched_report,
      contradicted_report: contradicted_report
    }
  end
end
