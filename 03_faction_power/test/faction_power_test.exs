defmodule FactionPowerTest do
  use ExUnit.Case

  alias Ash.Error.Forbidden
  alias FactionPower.Shipment

  setup do
    FactionPower.reset!()
    :ok
  end

  test "authority actors can see every manifest" do
    %{
      authority_actor: authority_actor,
      guild_manifest: guild_manifest,
      peer_manifest: peer_manifest,
      shadow_manifest: shadow_manifest
    } =
      FactionPower.bootstrap_registry!()

    manifests =
      FactionPower.visible_manifests!(authority_actor)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    assert manifests ==
             Enum.sort([
               guild_manifest.manifest_number,
               peer_manifest.manifest_number,
               shadow_manifest.manifest_number
             ])
  end

  test "guild actors only see civil manifests plus their own" do
    %{guild_actor: guild_actor, guild_manifest: guild_manifest, peer_manifest: peer_manifest} =
      FactionPower.bootstrap_registry!()

    manifests =
      FactionPower.visible_manifests!(guild_actor)
      |> Enum.map(& &1.manifest_number)
      |> Enum.sort()

    assert manifests == Enum.sort([guild_manifest.manifest_number, peer_manifest.manifest_number])
  end

  test "cleared syndicate actors can create restricted manifests" do
    %{syndicate_actor: syndicate_actor} = FactionPower.bootstrap_registry!()

    shipment =
      Shipment.register_restricted!(
        %{
          manifest_number: "GTA-3004",
          cargo_name: "sealed_archives",
          declared_value: 9_500,
          trader_id: syndicate_actor.id
        },
        actor: syndicate_actor
      )

    assert shipment.secrecy_level == :restricted
    assert shipment.corridor == :shadow
  end

  test "suspended actors cannot read or create manifests" do
    %{suspended_actor: suspended_actor} = FactionPower.bootstrap_registry!()

    assert_raise Forbidden, fn ->
      FactionPower.visible_manifests!(suspended_actor)
    end

    assert_raise Forbidden, fn ->
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-3005",
          cargo_name: "fuel_cells",
          declared_value: 1_800,
          trader_id: suspended_actor.id
        },
        actor: suspended_actor
      )
    end
  end
end
