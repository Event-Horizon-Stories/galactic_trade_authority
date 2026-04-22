defmodule GalacticTradeAuthorityTest do
  use ExUnit.Case

  alias Ash.Error.Forbidden
  alias Ash.Error.Invalid
  alias GalacticTradeAuthority.Shipment
  alias GalacticTradeAuthority.ShadowReport

  setup do
    GalacticTradeAuthority.reset!()
    :ok
  end

  test "official water shipments still keep their local tax path" do
    %{standard_water_shipment: shipment} = GalacticTradeAuthority.bootstrap_registry!()

    assert shipment.tax_due == 1_000
    assert shipment.route_decision == :standard
    assert shipment.route_classification == :locally_adjusted
    assert shipment.override_summary =~ "Mars import tax"
  end

  test "contracts still permit restricted official shipments" do
    %{permitted_restricted_shipment: shipment} = GalacticTradeAuthority.bootstrap_registry!()

    assert shipment.route_decision == :permitted_by_contract
    assert shipment.corridor == :shadow
    assert shipment.override_summary =~ "contract C-PERMIT-200"
  end

  test "official manifest visibility is still filtered by faction" do
    %{
      guild_actor: guild_actor,
      syndicate_actor: syndicate_actor,
      standard_water_shipment: standard_water_shipment,
      peer_civil_shipment: peer_civil_shipment,
      exempt_water_shipment: exempt_water_shipment,
      permitted_restricted_shipment: permitted_restricted_shipment
    } = GalacticTradeAuthority.bootstrap_registry!()

    guild_manifests =
      GalacticTradeAuthority.visible_manifests!(guild_actor)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    syndicate_manifests =
      GalacticTradeAuthority.visible_manifests!(syndicate_actor)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    assert guild_manifests ==
             Enum.sort([
               standard_water_shipment.manifest_number,
               peer_civil_shipment.manifest_number,
               exempt_water_shipment.manifest_number
             ])

    assert syndicate_manifests == [permitted_restricted_shipment.manifest_number]
  end

  test "off-ledger evidence can exist without any official shipment match" do
    %{unmatched_report: report} = GalacticTradeAuthority.bootstrap_registry!()

    assert report.ledger_status == :unmatched
    assert report.shipment_id == nil
    assert report.report_summary =~ "no official shipment matched"
  end

  test "evidence can reconcile to an official shipment without changing the shipment itself" do
    %{matched_report: report, official_shipment: shipment} =
      GalacticTradeAuthority.bootstrap_registry!()

    assert report.ledger_status == :matched
    assert report.shipment_id == shipment.id
    assert report.report_summary =~ shipment.manifest_number
  end

  test "contradictory evidence is preserved and flagged instead of discarded" do
    %{contradicted_report: report} = GalacticTradeAuthority.bootstrap_registry!()

    assert report.ledger_status == :contradicted
    assert report.shipment_id != nil
    assert report.report_summary =~ "conflicts on"
    assert report.report_summary =~ "resource"
  end

  test "a report still needs at least one structured lead" do
    assert_raise Invalid, ~r/expected at least one structured lead/, fn ->
      ShadowReport.record!(%{
        report_number: "SR-5004",
        source_type: :informant
      })
    end
  end

  test "suspended actors still cannot create official shipments" do
    %{
      suspended_actor: suspended_actor,
      origin_planet: origin_planet,
      tax_planet: destination_planet,
      untaxed_resource: resource
    } = GalacticTradeAuthority.bootstrap_registry!()

    assert_raise Forbidden, fn ->
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-5005",
          quantity: 8,
          declared_value: 2_000,
          trader_id: suspended_actor.id,
          origin_planet_id: origin_planet.id,
          destination_planet_id: destination_planet.id,
          resource_id: resource.id
        },
        actor: suspended_actor
      )
    end
  end
end
