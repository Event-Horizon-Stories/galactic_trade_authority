defmodule GalacticTradeAuthority.Changes.ApplyRegulatoryOutcome do
  @moduledoc """
  Writes the contract-aware regulatory outcome onto a shipment changeset.

  This keeps the action as the point where the manifest is judged. If the route
  is still blocked after considering contracts, the shipment never becomes real.
  """

  use Ash.Resource.Change

  alias GalacticTradeAuthority.Rules.RuleEngine

  @impl true
  def change(changeset, _opts, _context) do
    params = %{
      contract_id: Ash.Changeset.get_attribute(changeset, :contract_id),
      trader_id: Ash.Changeset.get_attribute(changeset, :trader_id),
      origin_planet_id: Ash.Changeset.get_attribute(changeset, :origin_planet_id),
      destination_planet_id: Ash.Changeset.get_attribute(changeset, :destination_planet_id),
      resource_id: Ash.Changeset.get_attribute(changeset, :resource_id),
      declared_value: Ash.Changeset.get_attribute(changeset, :declared_value)
    }

    outcome = RuleEngine.evaluate(params)

    if outcome.route_decision == :blocked do
      # A blocked route stays outside the ledger. The action should fail rather
      # than persisting a shipment that the Authority considers impossible.
      Ash.Changeset.add_error(
        changeset,
        field: :resource_id,
        message: "route blocked without matching contract override"
      )
    else
      changeset
      |> Ash.Changeset.change_attribute(:tax_due, outcome.tax_due)
      |> Ash.Changeset.change_attribute(:route_classification, outcome.route_classification)
      |> Ash.Changeset.change_attribute(:compliance_summary, outcome.compliance_summary)
      |> Ash.Changeset.change_attribute(:route_decision, outcome.route_decision)
      |> Ash.Changeset.change_attribute(:override_summary, outcome.override_summary)
    end
  end
end
