defmodule ContractLoopholesTest do
  use ExUnit.Case

  alias Ash.Error.Forbidden
  alias Ash.Error.Invalid
  alias ContractLoopholes.Shipment

  setup do
    ContractLoopholes.reset!()
    :ok
  end

  test "standard water shipment still pays Mars import tax" do
    %{standard_water_shipment: shipment} = ContractLoopholes.bootstrap_registry!()

    assert shipment.tax_due == 1_000
    assert shipment.route_classification == :locally_adjusted
    assert shipment.route_decision == :standard
    assert shipment.corridor == :civil
    assert shipment.override_summary =~ "Mars import tax"
  end

  test "matching exemption contract zeroes out the tax" do
    %{exempt_water_shipment: shipment} = ContractLoopholes.bootstrap_registry!()

    assert shipment.tax_due == 0
    assert shipment.route_classification == :locally_adjusted
    assert shipment.route_decision == :tax_exempt
    assert shipment.override_summary =~ "contract C-EXEMPT-100"
  end

  test "restricted shipment can become legal through permit contract" do
    %{permitted_restricted_shipment: shipment} = ContractLoopholes.bootstrap_registry!()

    assert shipment.route_decision == :permitted_by_contract
    assert shipment.corridor == :shadow
    assert shipment.override_summary =~ "contract C-PERMIT-200"
    assert shipment.override_summary =~ "Europa import ban"
  end

  test "read policies still filter manifests by faction" do
    %{
      authority_actor: authority_actor,
      guild_actor: guild_actor,
      syndicate_actor: syndicate_actor,
      standard_water_shipment: standard_water_shipment,
      peer_civil_shipment: peer_civil_shipment,
      exempt_water_shipment: exempt_water_shipment,
      permitted_restricted_shipment: permitted_restricted_shipment
    } = ContractLoopholes.bootstrap_registry!()

    authority_manifests =
      ContractLoopholes.visible_manifests!(authority_actor)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    guild_manifests =
      ContractLoopholes.visible_manifests!(guild_actor)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    syndicate_manifests =
      ContractLoopholes.visible_manifests!(syndicate_actor)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    assert authority_manifests ==
             Enum.sort([
               standard_water_shipment.manifest_number,
               peer_civil_shipment.manifest_number,
               exempt_water_shipment.manifest_number,
               permitted_restricted_shipment.manifest_number
             ])

    assert guild_manifests ==
             Enum.sort([
               standard_water_shipment.manifest_number,
               peer_civil_shipment.manifest_number,
               exempt_water_shipment.manifest_number
             ])

    assert syndicate_manifests == [permitted_restricted_shipment.manifest_number]
  end

  test "restricted shipment without a matching contract is rejected" do
    %{
      syndicate_actor: syndicate_actor,
      origin_planet: origin,
      restricted_planet: destination,
      restricted_resource: resource
    } =
      ContractLoopholes.bootstrap_registry!()

    assert_raise Invalid, ~r/route blocked without matching contract override/, fn ->
      Shipment.register_restricted!(
        %{
          manifest_number: "GTA-4005",
          quantity: 6,
          declared_value: 16_000,
          trader_id: syndicate_actor.id,
          origin_planet_id: origin.id,
          destination_planet_id: destination.id,
          resource_id: resource.id
        },
        actor: syndicate_actor
      )
    end
  end

  test "suspended actors still cannot create shipment records" do
    %{
      suspended_actor: suspended_actor,
      origin_planet: origin,
      tax_planet: destination,
      untaxed_resource: resource
    } = ContractLoopholes.bootstrap_registry!()

    assert_raise Forbidden, fn ->
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-4006",
          quantity: 12,
          declared_value: 1_500,
          trader_id: suspended_actor.id,
          origin_planet_id: origin.id,
          destination_planet_id: destination.id,
          resource_id: resource.id
        },
        actor: suspended_actor
      )
    end
  end
end
