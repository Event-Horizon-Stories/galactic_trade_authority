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

  test "official water shipments still keep their local tax path within a tenant" do
    %{primary: primary, primary_tenant: tenant} = GalacticTradeAuthority.bootstrap_registry!()

    shipment = primary.standard_water_shipment

    assert shipment.tax_due == 1_000
    assert shipment.route_decision == :standard
    assert shipment.route_classification == :locally_adjusted
    assert shipment.override_summary =~ "Mars import tax"

    assert GalacticTradeAuthority.case_file_for_manifest!(shipment.manifest_number, tenant).shipment.id ==
             shipment.id
  end

  test "contracts still permit restricted official shipments within a tenant" do
    %{primary: primary} = GalacticTradeAuthority.bootstrap_registry!()

    shipment = primary.permitted_restricted_shipment

    assert shipment.route_decision == :permitted_by_contract
    assert shipment.corridor == :shadow
    assert shipment.override_summary =~ "contract C-PERMIT-200"
  end

  test "official manifest visibility is still filtered by faction within a tenant" do
    %{primary: primary, primary_tenant: tenant} = GalacticTradeAuthority.bootstrap_registry!()

    guild_manifests =
      GalacticTradeAuthority.visible_manifests!(primary.guild_actor, tenant)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    syndicate_manifests =
      GalacticTradeAuthority.visible_manifests!(primary.syndicate_actor, tenant)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    assert guild_manifests ==
             Enum.sort([
               primary.standard_water_shipment.manifest_number,
               primary.peer_civil_shipment.manifest_number,
               primary.exempt_water_shipment.manifest_number
             ])

    assert syndicate_manifests == [primary.permitted_restricted_shipment.manifest_number]
  end

  test "audit trail records who registered, reviewed, and later flagged a manifest within a tenant" do
    %{primary: primary, primary_tenant: tenant} = GalacticTradeAuthority.bootstrap_registry!()

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
           ] =
             GalacticTradeAuthority.audit_trail_for_manifest!(
               primary.investigated_shipment.manifest_number,
               tenant
             )

    assert registration_summary =~ "SHADOW-BROKER registered manifest GTA-4004 through override"
    assert registration_summary =~ "contract C-PERMIT-200"
  end

  test "case files explain who approved a slipped shipment and who flagged it later within a tenant" do
    %{primary: primary} = GalacticTradeAuthority.bootstrap_registry!()

    case_file = primary.case_file

    assert case_file.manifest == primary.investigated_shipment.manifest_number
    assert case_file.shipment.route_decision == :permitted_by_contract
    assert case_file.approved_by == "INSPECTOR-IX"
    assert case_file.flagged_by == "AUDITOR-12"
    assert Enum.map(case_file.reports, & &1.ledger_status) == [:contradicted]
  end

  test "unmatched evidence still becomes a traceable audit event within a tenant" do
    %{primary: primary, primary_tenant: tenant} = GalacticTradeAuthority.bootstrap_registry!()

    report = primary.unmatched_report

    assert report.ledger_status == :unmatched

    assert GalacticTradeAuthority.audit_trail_for_manifest!(report.reported_manifest, tenant) == [
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

  test "the same manifest number can exist in two sectors without colliding" do
    %{
      primary: primary,
      secondary: secondary,
      primary_tenant: primary_tenant,
      secondary_tenant: secondary_tenant
    } = GalacticTradeAuthority.bootstrap_registry!()

    assert primary.standard_water_shipment.manifest_number == "GTA-4001"
    assert secondary.standard_water_shipment.manifest_number == "GTA-4001"

    assert primary.standard_water_shipment.tax_due == 1_000
    assert secondary.standard_water_shipment.tax_due == 600

    assert GalacticTradeAuthority.case_file_for_manifest!("GTA-4004", primary_tenant).approved_by ==
             "INSPECTOR-IX"

    assert GalacticTradeAuthority.case_file_for_manifest!("GTA-4004", secondary_tenant).approved_by ==
             "INSPECTOR-KAPPA"
  end

  test "reads and investigations do not leak across tenants" do
    %{
      primary: primary,
      secondary: secondary,
      primary_tenant: primary_tenant,
      secondary_tenant: secondary_tenant
    } = GalacticTradeAuthority.bootstrap_registry!()

    primary_manifests =
      GalacticTradeAuthority.visible_manifests!(primary.guild_actor, primary_tenant)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    secondary_manifests =
      GalacticTradeAuthority.visible_manifests!(secondary.guild_actor, secondary_tenant)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    assert primary_manifests == ["GTA-4001", "GTA-4002", "GTA-4003"]
    assert secondary_manifests == ["GTA-4001", "GTA-4002", "GTA-4003"]

    assert GalacticTradeAuthority.audit_trail_for_manifest!("GTA-4004", primary_tenant)
           |> Enum.map(& &1.actor) == ["SHADOW-BROKER", "INSPECTOR-IX", "AUDITOR-12"]

    assert GalacticTradeAuthority.audit_trail_for_manifest!("GTA-4004", secondary_tenant)
           |> Enum.map(& &1.actor) == ["NIGHT-BROKER", "INSPECTOR-KAPPA", "AUDITOR-88"]
  end

  test "multitenant resources require a tenant" do
    %{primary: primary} = GalacticTradeAuthority.bootstrap_registry!()

    assert_raise Invalid, ~r/require a tenant to be specified/, fn ->
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-5005",
          quantity: 8,
          declared_value: 2_000,
          trader_id: primary.guild_actor.id,
          origin_planet_id: primary.origin_planet.id,
          destination_planet_id: primary.tax_planet.id,
          resource_id: primary.taxed_resource.id
        },
        actor: primary.guild_actor
      )
    end
  end

  test "a report still needs at least one structured lead inside a tenant" do
    assert_raise Invalid, ~r/expected at least one structured lead/, fn ->
      ShadowReport.record!(
        %{
          report_number: "SR-5004",
          source_type: :informant
        },
        tenant: "sol"
      )
    end
  end

  test "suspended actors still cannot create official shipments inside their tenant" do
    %{primary: primary, primary_tenant: tenant} = GalacticTradeAuthority.bootstrap_registry!()

    assert_raise Forbidden, fn ->
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-5006",
          quantity: 8,
          declared_value: 2_000,
          trader_id: primary.suspended_actor.id,
          origin_planet_id: primary.origin_planet.id,
          destination_planet_id: primary.tax_planet.id,
          resource_id: primary.untaxed_resource.id
        },
        actor: primary.suspended_actor,
        tenant: tenant
      )
    end
  end
end
