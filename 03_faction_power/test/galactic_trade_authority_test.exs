defmodule GalacticTradeAuthorityTest do
  use ExUnit.Case

  alias Ash.Error.Forbidden
  alias GalacticTradeAuthority.Shipment

  setup do
    GalacticTradeAuthority.reset!()
    :ok
  end

  test "authority actors can see every manifest" do
    %{
      authority_actor: authority_actor,
      guild_manifest: guild_manifest,
      peer_manifest: peer_manifest,
      shadow_manifest: shadow_manifest
    } =
      GalacticTradeAuthority.bootstrap_registry!()

    manifests =
      GalacticTradeAuthority.visible_manifests!(authority_actor)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    assert manifests ==
             Enum.sort([
               guild_manifest.manifest_number,
               peer_manifest.manifest_number,
               shadow_manifest.manifest_number
             ])
  end

  test "guild actors still register taxed legal shipments under local law" do
    %{guild_manifest: guild_manifest, applied_rules: applied_rules} =
      GalacticTradeAuthority.bootstrap_registry!()

    assert guild_manifest.tax_due == 1_000
    assert guild_manifest.route_classification == :locally_adjusted
    assert guild_manifest.corridor == :civil
    assert guild_manifest.compliance_summary =~ "Titan export tax"
    assert guild_manifest.compliance_summary =~ "Mars import tax"

    assert Enum.map(applied_rules, & &1.rationale) == [
             "Titan ice extraction duty",
             "Mars aquifer restoration levy"
           ]
  end

  test "guild actors only see civil manifests plus their own" do
    %{guild_actor: guild_actor, guild_manifest: guild_manifest, peer_manifest: peer_manifest} =
      GalacticTradeAuthority.bootstrap_registry!()

    manifests =
      GalacticTradeAuthority.visible_manifests!(guild_actor)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    assert manifests == Enum.sort([guild_manifest.manifest_number, peer_manifest.manifest_number])
  end

  test "cleared syndicate actors can create restricted manifests" do
    %{
      syndicate_actor: syndicate_actor,
      origin_planet: origin_planet,
      destination_planet: destination_planet,
      restricted_resource: restricted_resource
    } = GalacticTradeAuthority.bootstrap_registry!()

    shipment =
      Shipment.register_restricted!(
        %{
          manifest_number: "GTA-3004",
          quantity: 4,
          declared_value: 9_500,
          trader_id: syndicate_actor.id,
          origin_planet_id: origin_planet.id,
          destination_planet_id: destination_planet.id,
          resource_id: restricted_resource.id
        },
        actor: syndicate_actor
      )

    assert shipment.secrecy_level == :restricted
    assert shipment.corridor == :shadow
  end

  test "planetary bans still reject shipments before authorization can make them real" do
    %{
      authority_actor: authority_actor,
      origin_planet: origin_planet,
      blocked_planet: blocked_planet,
      blocked_resource: blocked_resource
    } = GalacticTradeAuthority.bootstrap_registry!()

    assert_raise Ash.Error.Invalid, ~r/Europa import/, fn ->
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-3006",
          quantity: 4,
          declared_value: 12_000,
          trader_id: authority_actor.id,
          origin_planet_id: origin_planet.id,
          destination_planet_id: blocked_planet.id,
          resource_id: blocked_resource.id
        },
        actor: authority_actor
      )
    end
  end

  test "suspended actors cannot read or create manifests" do
    %{
      suspended_actor: suspended_actor,
      origin_planet: origin_planet,
      destination_planet: destination_planet,
      untaxed_resource: untaxed_resource
    } = GalacticTradeAuthority.bootstrap_registry!()

    assert_raise Forbidden, fn ->
      GalacticTradeAuthority.visible_manifests!(suspended_actor)
    end

    assert_raise Forbidden, fn ->
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-3005",
          quantity: 9,
          declared_value: 1_800,
          trader_id: suspended_actor.id,
          origin_planet_id: origin_planet.id,
          destination_planet_id: destination_planet.id,
          resource_id: untaxed_resource.id
        },
        actor: suspended_actor
      )
    end
  end
end
