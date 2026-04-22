defmodule GalacticTradeAuthorityTest do
  use ExUnit.Case

  alias Ash.Error.Invalid
  alias GalacticTradeAuthority.Resources.Shipment

  setup do
    GalacticTradeAuthority.reset!()
    :ok
  end

  test "accepts a taxed shipment and records the local adjustments" do
    %{shipment: shipment, applied_rules: applied_rules} =
      GalacticTradeAuthority.bootstrap_registry!()

    assert shipment.manifest_number == "GTA-2001"
    assert shipment.tax_due == 1_000
    assert shipment.route_classification == :locally_adjusted

    assert shipment.compliance_summary =~ "Titan export tax"
    assert shipment.compliance_summary =~ "Mars import tax"

    assert Enum.map(applied_rules, & &1.rationale) == [
             "Titan ice extraction duty",
             "Mars aquifer restoration levy"
           ]
  end

  test "rejects a shipment banned by a destination planet" do
    %{
      trader: trader,
      origin_planet: origin_planet,
      blocked_planet: blocked_planet,
      blocked_resource: blocked_resource
    } = GalacticTradeAuthority.bootstrap_registry!()

    assert_raise Invalid, ~r/Europa import/, fn ->
      Shipment.register!(%{
        manifest_number: "GTA-2002",
        quantity: 4,
        declared_value: 12_000,
        trader_id: trader.id,
        origin_planet_id: origin_planet.id,
        destination_planet_id: blocked_planet.id,
        resource_id: blocked_resource.id
      })
    end
  end

  test "keeps an unregulated route unchanged" do
    %{trader: trader, destination_planet: destination_planet, untaxed_resource: untaxed_resource} =
      GalacticTradeAuthority.bootstrap_registry!()

    europa =
      GalacticTradeAuthority.Resources.Planet.list!()
      |> Enum.find(&(&1.name == "Europa"))

    shipment =
      Shipment.register!(%{
        manifest_number: "GTA-2003",
        quantity: 18,
        declared_value: 2_500,
        trader_id: trader.id,
        origin_planet_id: destination_planet.id,
        destination_planet_id: europa.id,
        resource_id: untaxed_resource.id
      })

    assert shipment.tax_due == 0
    assert shipment.route_classification == :standard
    assert shipment.compliance_summary == nil
  end

  test "lists the accepted shipments in the chapter registry" do
    %{shipment: shipment} = GalacticTradeAuthority.bootstrap_registry!()

    [listed_shipment] = GalacticTradeAuthority.list_shipments!()

    assert listed_shipment.id == shipment.id
  end
end
