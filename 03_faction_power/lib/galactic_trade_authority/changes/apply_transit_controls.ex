defmodule GalacticTradeAuthority.Changes.ApplyTransitControls do
  use Ash.Resource.Change

  alias GalacticTradeAuthority.Rules.LocalRules

  @impl true
  def change(changeset, _opts, _context) do
    origin_planet_id = Ash.Changeset.get_attribute(changeset, :origin_planet_id)
    destination_planet_id = Ash.Changeset.get_attribute(changeset, :destination_planet_id)
    resource_id = Ash.Changeset.get_attribute(changeset, :resource_id)
    declared_value = Ash.Changeset.get_attribute(changeset, :declared_value) || 0

    total_tax_rate =
      LocalRules.total_tax_rate(origin_planet_id, destination_planet_id, resource_id)

    tax_due = div(declared_value * total_tax_rate, 100)

    classification =
      if total_tax_rate > 0 do
        :locally_adjusted
      else
        :standard
      end

    summary =
      LocalRules.rule_summary(origin_planet_id, destination_planet_id, resource_id)
      |> Enum.join("; ")

    changeset
    |> Ash.Changeset.change_attribute(:tax_due, tax_due)
    |> Ash.Changeset.change_attribute(:route_classification, classification)
    |> Ash.Changeset.change_attribute(:compliance_summary, blank_to_nil(summary))
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
