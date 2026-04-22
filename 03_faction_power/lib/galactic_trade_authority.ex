defmodule GalacticTradeAuthority do
  @moduledoc """
  Chapter 3 helper API for the Galactic Trade Authority series.

  This chapter turns a legal registry into a political one:

  - traders act as the authorization subject
  - local route law still applies before records become official
  - factions see different slices of the ledger
  - restricted manifests require special actor clearance
  """

  alias GalacticTradeAuthority.Resources.{Planet, PlanetRule, Shipment, TradeResource, Trader}

  @resources [Shipment, PlanetRule, TradeResource, Planet, Trader]

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
  Builds the chapter 3 actor set, local law, and a politically filtered ledger.
  """
  def bootstrap_registry! do
    reset!()

    authority_actor =
      Trader.register!(%{
        callsign: "INSPECTOR-IX",
        faction: :authority,
        reputation: 95,
        status: :registered,
        override_clearance: true
      })

    guild_actor =
      Trader.register!(%{
        callsign: "GUILD-HAULER",
        faction: :guild,
        reputation: 81,
        status: :registered,
        override_clearance: false
      })

    guild_peer =
      Trader.register!(%{
        callsign: "GUILD-COURIER",
        faction: :guild,
        reputation: 74,
        status: :registered,
        override_clearance: false
      })

    syndicate_actor =
      Trader.register!(%{
        callsign: "SHADOW-BROKER",
        faction: :syndicate,
        reputation: 66,
        status: :registered,
        override_clearance: true
      })

    suspended_actor =
      Trader.register!(%{
        callsign: "GROUNDED-17",
        faction: :guild,
        reputation: 12,
        status: :suspended,
        override_clearance: false
      })

    mars =
      Planet.register!(%{
        name: "Mars",
        sector: "Inner Belt",
        customs_index: 4
      })

    titan =
      Planet.register!(%{
        name: "Titan",
        sector: "Outer Ring",
        customs_index: 3
      })

    europa =
      Planet.register!(%{
        name: "Europa",
        sector: "Jovian Reach",
        customs_index: 5
      })

    water =
      TradeResource.register!(%{
        name: "water",
        category: :essential,
        base_unit: "kiloliter",
        legal_status: :legal
      })

    grain =
      TradeResource.register!(%{
        name: "grain",
        category: :essential,
        base_unit: "ton",
        legal_status: :legal
      })

    prototype_drives =
      TradeResource.register!(%{
        name: "prototype_drives",
        category: :restricted,
        base_unit: "crate",
        legal_status: :restricted
      })

    ai_chips =
      TradeResource.register!(%{
        name: "ai_chips",
        category: :industrial,
        base_unit: "crate",
        legal_status: :legal
      })

    titan_export_water =
      PlanetRule.register!(%{
        direction: :export,
        effect: :tax,
        tax_rate: 2,
        rationale: "Titan ice extraction duty",
        planet_id: titan.id,
        resource_id: water.id
      })

    mars_import_water =
      PlanetRule.register!(%{
        direction: :import,
        effect: :tax,
        tax_rate: 8,
        rationale: "Mars aquifer restoration levy",
        planet_id: mars.id,
        resource_id: water.id
      })

    europa_import_ai_ban =
      PlanetRule.register!(%{
        direction: :import,
        effect: :ban,
        rationale: "Europa sentient systems moratorium",
        planet_id: europa.id,
        resource_id: ai_chips.id
      })

    guild_manifest =
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-3001",
          quantity: 25,
          declared_value: 10_000,
          trader_id: guild_actor.id,
          origin_planet_id: titan.id,
          destination_planet_id: mars.id,
          resource_id: water.id
        },
        actor: guild_actor
      )

    peer_manifest =
      Shipment.register_standard!(
        %{
          manifest_number: "GTA-3002",
          quantity: 12,
          declared_value: 4_500,
          trader_id: guild_peer.id,
          origin_planet_id: mars.id,
          destination_planet_id: titan.id,
          resource_id: grain.id
        },
        actor: guild_peer
      )

    shadow_manifest =
      Shipment.register_restricted!(
        %{
          manifest_number: "GTA-3003",
          quantity: 6,
          declared_value: 12_000,
          trader_id: syndicate_actor.id,
          origin_planet_id: titan.id,
          destination_planet_id: mars.id,
          resource_id: prototype_drives.id
        },
        actor: syndicate_actor
      )

    %{
      authority_actor: authority_actor,
      guild_actor: guild_actor,
      guild_peer: guild_peer,
      syndicate_actor: syndicate_actor,
      suspended_actor: suspended_actor,
      origin_planet: titan,
      destination_planet: mars,
      blocked_planet: europa,
      taxed_resource: water,
      untaxed_resource: grain,
      restricted_resource: prototype_drives,
      blocked_resource: ai_chips,
      applied_rules: [titan_export_water, mars_import_water],
      blocked_rule: europa_import_ai_ban,
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
