defmodule ContractLoopholesTest do
  use ExUnit.Case

  alias Ash.Error.Invalid
  alias ContractLoopholes.Shipment

  setup do
    ContractLoopholes.reset!()
    :ok
  end

  test "standard water shipment still pays Mars import tax" do
    %{standard_water_shipment: shipment} = ContractLoopholes.bootstrap_registry!()

    assert shipment.tax_due == 800
    assert shipment.route_decision == :standard
    assert shipment.override_summary =~ "Mars import tax"
  end

  test "matching exemption contract zeroes out the tax" do
    %{exempt_water_shipment: shipment} = ContractLoopholes.bootstrap_registry!()

    assert shipment.tax_due == 0
    assert shipment.route_decision == :tax_exempt
    assert shipment.override_summary =~ "contract C-EXEMPT-100"
  end

  test "restricted shipment can become legal through permit contract" do
    %{permitted_restricted_shipment: shipment} = ContractLoopholes.bootstrap_registry!()

    assert shipment.route_decision == :permitted_by_contract
    assert shipment.override_summary =~ "contract C-PERMIT-200"
    assert shipment.override_summary =~ "Europa import ban"
  end

  test "restricted shipment without a matching contract is rejected" do
    %{
      trader: trader,
      origin_planet: origin,
      restricted_planet: destination,
      restricted_resource: resource
    } =
      ContractLoopholes.bootstrap_registry!()

    assert_raise Invalid, ~r/route blocked without matching contract override/, fn ->
      Shipment.register!(%{
        manifest_number: "GTA-4004",
        quantity: 6,
        declared_value: 16_000,
        trader_id: trader.id,
        origin_planet_id: origin.id,
        destination_planet_id: destination.id,
        resource_id: resource.id
      })
    end
  end
end
