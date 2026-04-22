defmodule GalacticTradeAuthority.Validations.RequireStructuredLead do
  @moduledoc """
  Requires enough structured evidence to investigate a tenant-scoped report.
  """

  use Ash.Resource.Validation

  @lead_fields [
    :shipment_id,
    :reported_manifest,
    :trader_id,
    :resource_id,
    :origin_planet_id,
    :destination_planet_id
  ]

  @impl true
  def validate(changeset, _opts, _context) do
    if Enum.any?(@lead_fields, &present?(Ash.Changeset.get_attribute(changeset, &1))) do
      :ok
    else
      {:error, field: :base, message: "expected at least one structured lead"}
    end
  end

  defp present?(value) when is_binary(value), do: value != ""
  defp present?(nil), do: false
  defp present?(_value), do: true
end
