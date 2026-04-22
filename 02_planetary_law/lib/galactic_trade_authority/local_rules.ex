defmodule GalacticTradeAuthority.LocalRules do
  @moduledoc """
  Resolves the planet-level trade rules that apply to one shipment route.

  Lesson 2 keeps the core registry intact and introduces local law as a layer
  derived from origin, destination, and resource.
  """

  alias GalacticTradeAuthority.{Planet, PlanetRule, TradeResource}

  @doc """
  Returns every planetary rule that applies to a shipment route.
  """
  def applicable_rules(origin_planet_id, destination_planet_id, resource_id) do
    PlanetRule.list!()
    |> Enum.filter(fn rule ->
      rule.resource_id == resource_id and
        ((rule.direction == :export and rule.planet_id == origin_planet_id) or
           (rule.direction == :import and rule.planet_id == destination_planet_id))
    end)
  end

  @doc """
  Returns the first ban that blocks the route, if one exists.
  """
  def first_ban(origin_planet_id, destination_planet_id, resource_id) do
    applicable_rules(origin_planet_id, destination_planet_id, resource_id)
    |> Enum.find(&(&1.effect == :ban))
  end

  @doc """
  Sums the tax rates from all applicable route rules.
  """
  def total_tax_rate(origin_planet_id, destination_planet_id, resource_id) do
    applicable_rules(origin_planet_id, destination_planet_id, resource_id)
    |> Enum.filter(&(&1.effect == :tax))
    |> Enum.reduce(0, fn rule, acc -> acc + (rule.tax_rate || 0) end)
  end

  @doc """
  Builds a readable summary of the local law that shaped the route.
  """
  def rule_summary(origin_planet_id, destination_planet_id, resource_id) do
    origin_planet = find_planet!(origin_planet_id)
    destination_planet = find_planet!(destination_planet_id)
    resource = find_resource!(resource_id)

    applicable_rules(origin_planet_id, destination_planet_id, resource_id)
    |> Enum.map(fn rule ->
      planet = if rule.direction == :export, do: origin_planet, else: destination_planet

      "#{planet.name} #{rule.direction} #{rule.effect}: #{resource.name} - #{rule.rationale}"
    end)
  end

  @doc """
  Loads the route context used when building ban and tax messages.
  """
  def find_rule_context!(origin_planet_id, destination_planet_id, resource_id) do
    %{
      origin_planet: find_planet!(origin_planet_id),
      destination_planet: find_planet!(destination_planet_id),
      resource: find_resource!(resource_id)
    }
  end

  defp find_planet!(planet_id) do
    Planet.list!()
    |> Enum.find(&(&1.id == planet_id))
  end

  defp find_resource!(resource_id) do
    TradeResource.list!()
    |> Enum.find(&(&1.id == resource_id))
  end
end
