defmodule GalacticTradeAuthorityTest do
  use ExUnit.Case

  alias Ash.Error.Forbidden
  alias Ash.Error.Invalid
  alias GalacticTradeAuthority.Resources.Shipment
  alias GalacticTradeAuthority.Resources.ShadowReport

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

  test "audit trail records who registered, reviewed, and later flagged a manifest" do
    %{investigated_shipment: shipment} = GalacticTradeAuthority.bootstrap_registry!()

    assert [
             %{
               audit_code: "AR-6004",
               event_type: :shipment_registered,
               finding: :approved,
               actor: "SHADOW-BROKER",
               summary: registration_summary
             },
             %{
               audit_code: "AR-6005",
               event_type: :override_reviewed,
               finding: :approved,
               actor: "INSPECTOR-IX",
               summary: "Inspector IX approved contract C-PERMIT-200 for manifest GTA-4004."
             },
             %{
               audit_code: "AR-6008",
               event_type: :shadow_report_recorded,
               finding: :contradicted,
               actor: "AUDITOR-12",
               summary: "AUDITOR-12 recorded contradictory evidence against manifest GTA-4004."
             }
           ] = GalacticTradeAuthority.audit_trail_for_manifest!(shipment.manifest_number)

    assert registration_summary =~ "SHADOW-BROKER registered manifest GTA-4004 through override"
    assert registration_summary =~ "contract C-PERMIT-200"
  end

  test "case files explain who approved a slipped shipment and who flagged it later" do
    %{case_file: case_file, investigated_shipment: shipment} =
      GalacticTradeAuthority.bootstrap_registry!()

    assert case_file.manifest == shipment.manifest_number
    assert case_file.shipment.route_decision == :permitted_by_contract
    assert case_file.approved_by == "INSPECTOR-IX"
    assert case_file.flagged_by == "AUDITOR-12"
    assert Enum.map(case_file.reports, & &1.ledger_status) == [:contradicted]
  end

  test "unmatched evidence still becomes a traceable audit event" do
    %{unmatched_report: report} = GalacticTradeAuthority.bootstrap_registry!()

    assert report.ledger_status == :unmatched

    assert GalacticTradeAuthority.audit_trail_for_manifest!(report.reported_manifest) == [
             %{
               audit_code: "AR-6006",
               event_type: :shadow_report_recorded,
               finding: :unmatched,
               actor: "AUDITOR-12",
               summary:
                 "AUDITOR-12 recorded evidence for GTA-5999 with no official shipment match."
             }
           ]
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
