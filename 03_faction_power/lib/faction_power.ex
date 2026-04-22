defmodule FactionPower do
  @moduledoc """
  Chapter 3 helper API for the Galactic Trade Authority series.

  This chapter turns a legal registry into a political one:

  - traders act as the authorization subject
  - factions see different slices of the ledger
  - restricted manifests require special actor clearance
  """

  alias FactionPower.{Shipment, Trader}

  @resources [Shipment, Trader]

  @doc """
  Clears ETS-backed lesson state so each example or test starts from a known registry.
  """
  def reset! do
    Enum.each(@resources, fn resource ->
      Ash.read!(resource, authorize?: false)
      |> Enum.each(&Ash.destroy!(&1, authorize?: false))

      Ash.DataLayer.Ets.stop(resource)
    end)
  end

  @doc """
  Builds the chapter 3 actor set and a small shipment ledger.
  """
  def bootstrap_registry! do
    reset!()

    authority_actor =
      Trader.register!(%{
        callsign: "INSPECTOR-IX",
        faction: :authority,
        status: :registered,
        override_clearance: true
      })

    guild_actor =
      Trader.register!(%{
        callsign: "GUILD-HAULER",
        faction: :guild,
        status: :registered,
        override_clearance: false
      })

    guild_peer =
      Trader.register!(%{
        callsign: "GUILD-COURIER",
        faction: :guild,
        status: :registered,
        override_clearance: false
      })

    syndicate_actor =
      Trader.register!(%{
        callsign: "SHADOW-BROKER",
        faction: :syndicate,
        status: :registered,
        override_clearance: true
      })

    suspended_actor =
      Trader.register!(%{
        callsign: "GROUNDED-17",
        faction: :guild,
        status: :suspended,
        override_clearance: false
      })

    guild_manifest =
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-3001",
          cargo_name: "grain",
          declared_value: 2_000,
          trader_id: guild_actor.id
        },
        actor: guild_actor
      )

    peer_manifest =
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-3002",
          cargo_name: "medical_supplies",
          declared_value: 4_500,
          trader_id: guild_peer.id
        },
        actor: guild_peer
      )

    shadow_manifest =
      Shipment.register_restricted!(
        %{
          manifest_number: "GTA-3003",
          cargo_name: "prototype_drives",
          declared_value: 12_000,
          trader_id: syndicate_actor.id
        },
        actor: syndicate_actor
      )

    %{
      authority_actor: authority_actor,
      guild_actor: guild_actor,
      guild_peer: guild_peer,
      syndicate_actor: syndicate_actor,
      suspended_actor: suspended_actor,
      guild_manifest: guild_manifest,
      peer_manifest: peer_manifest,
      shadow_manifest: shadow_manifest
    }
  end

  @doc """
  Returns the manifests visible to the given actor.
  """
  def visible_manifests!(actor) do
    Shipment.list!(actor: actor)
  end
end
