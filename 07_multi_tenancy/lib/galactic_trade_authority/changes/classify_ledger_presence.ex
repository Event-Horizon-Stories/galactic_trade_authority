defmodule GalacticTradeAuthority.Changes.ClassifyLedgerPresence do
  @moduledoc """
  Derives ledger status for a report using only the current tenant's data.
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    result =
      %{
        shipment_id: Ash.Changeset.get_attribute(changeset, :shipment_id),
        reported_manifest: Ash.Changeset.get_attribute(changeset, :reported_manifest),
        trader_id: Ash.Changeset.get_attribute(changeset, :trader_id),
        resource_id: Ash.Changeset.get_attribute(changeset, :resource_id),
        origin_planet_id: Ash.Changeset.get_attribute(changeset, :origin_planet_id),
        destination_planet_id: Ash.Changeset.get_attribute(changeset, :destination_planet_id)
      }
      |> GalacticTradeAuthority.Investigations.LedgerMatcher.classify(changeset.tenant)

    # Persist the comparison result so later audit and query code can rely on a
    # stable official classification for the report.
    changeset
    |> Ash.Changeset.change_attribute(:ledger_status, result.ledger_status)
    |> Ash.Changeset.change_attribute(:report_summary, result.report_summary)
    |> maybe_set_shipment_id(result.shipment_id)
  end

  defp maybe_set_shipment_id(changeset, nil), do: changeset

  defp maybe_set_shipment_id(changeset, shipment_id),
    do: Ash.Changeset.change_attribute(changeset, :shipment_id, shipment_id)
end
