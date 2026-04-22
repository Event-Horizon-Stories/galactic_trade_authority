defmodule GalacticTradeAuthority.Validations.AllowedByPlanetaryLaw do
  use Ash.Resource.Validation

  alias GalacticTradeAuthority.LocalRules

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def supports(_opts), do: [Ash.Changeset]

  @impl true
  def validate(changeset, _opts, _context) do
    origin_planet_id = Ash.Changeset.get_attribute(changeset, :origin_planet_id)
    destination_planet_id = Ash.Changeset.get_attribute(changeset, :destination_planet_id)
    resource_id = Ash.Changeset.get_attribute(changeset, :resource_id)

    case LocalRules.first_ban(origin_planet_id, destination_planet_id, resource_id) do
      nil ->
        :ok

      rule ->
        context =
          LocalRules.find_rule_context!(origin_planet_id, destination_planet_id, resource_id)

        planet =
          if rule.direction == :export do
            context.origin_planet
          else
            context.destination_planet
          end

        {:error,
         field: :resource_id,
         message:
           "#{context.resource.name} is banned on #{planet.name} #{rule.direction}: #{rule.rationale}"}
    end
  end
end
