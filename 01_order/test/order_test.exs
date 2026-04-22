defmodule OrderTest do
  use ExUnit.Case

  alias Ash.Error.Invalid
  alias Order.Shipment

  setup do
    Order.reset!()
    :ok
  end

  test "registers the chapter 1 official trade flow" do
    %{shipment: shipment, trader: trader, origin_planet: origin, destination_planet: destination} =
      Order.bootstrap_registry!()

    [listed_shipment] = Order.list_shipments!()

    assert shipment.manifest_number == "GTA-1001"
    assert shipment.status == :registered
    assert trader.callsign == "ORBITAL-3"
    assert origin.name == "Mars"
    assert destination.name == "Titan"
    assert listed_shipment.id == shipment.id
  end

  test "rejects a shipment with a malformed manifest number" do
    %{trader: trader, origin_planet: origin, destination_planet: destination, resource: resource} =
      Order.bootstrap_registry!()

    assert_raise Invalid, fn ->
      Shipment.register!(%{
        manifest_number: "INVALID-77",
        quantity: 10,
        declared_value: 500,
        trader_id: trader.id,
        origin_planet_id: origin.id,
        destination_planet_id: destination.id,
        resource_id: resource.id
      })
    end
  end

  test "rejects a shipment with a non-positive quantity" do
    %{trader: trader, origin_planet: origin, destination_planet: destination, resource: resource} =
      Order.bootstrap_registry!()

    assert_raise Invalid, fn ->
      Shipment.register!(%{
        manifest_number: "GTA-1002",
        quantity: 0,
        declared_value: 500,
        trader_id: trader.id,
        origin_planet_id: origin.id,
        destination_planet_id: destination.id,
        resource_id: resource.id
      })
    end
  end

  test "rejects a shipment whose origin and destination are the same" do
    %{trader: trader, origin_planet: origin, resource: resource} = Order.bootstrap_registry!()

    assert_raise Invalid, fn ->
      Shipment.register!(%{
        manifest_number: "GTA-1003",
        quantity: 8,
        declared_value: 750,
        trader_id: trader.id,
        origin_planet_id: origin.id,
        destination_planet_id: origin.id,
        resource_id: resource.id
      })
    end
  end
end
