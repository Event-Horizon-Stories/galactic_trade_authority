defmodule GalacticTradeAuthority.Investigations.LedgerMatcher do
  @moduledoc """
  Compares a tenant's shadow reports with that same tenant's official ledger.

  The matcher preserves the chapter 5 behavior while making tenant isolation an
  explicit part of every shipment lookup.
  """

  alias GalacticTradeAuthority.Resources.Shipment

  @comparison_fields [
    {:reported_manifest, :manifest_number, "manifest"},
    {:trader_id, :trader_id, "trader"},
    {:resource_id, :resource_id, "resource"},
    {:origin_planet_id, :origin_planet_id, "origin"},
    {:destination_planet_id, :destination_planet_id, "destination"}
  ]

  @doc """
  Classifies a report as unmatched, matched, or contradicted within one tenant.
  """
  def classify(params, tenant) do
    case find_shipment(params, tenant) do
      nil ->
        %{
          ledger_status: :unmatched,
          shipment_id: nil,
          report_summary: unmatched_summary(params)
        }

      shipment ->
        case mismatches(params, shipment) do
          [] ->
            %{
              ledger_status: :matched,
              shipment_id: shipment.id,
              report_summary: "matched official shipment #{shipment.manifest_number}"
            }

          fields ->
            %{
              ledger_status: :contradicted,
              shipment_id: shipment.id,
              report_summary:
                "matched official shipment #{shipment.manifest_number} but conflicts on #{Enum.join(fields, ", ")}"
            }
        end
    end
  end

  defp find_shipment(%{shipment_id: shipment_id}, tenant) when is_binary(shipment_id) do
    # When both keys are present, trust the explicit shipment reference first and
    # let reported_manifest participate only in contradiction detection.
    Ash.read!(Shipment, authorize?: false, tenant: tenant)
    |> Enum.find(&(&1.id == shipment_id))
  end

  defp find_shipment(%{reported_manifest: manifest}, tenant) when is_binary(manifest) do
    Ash.read!(Shipment, authorize?: false, tenant: tenant)
    |> Enum.find(&(&1.manifest_number == manifest))
  end

  defp find_shipment(_params, _tenant), do: nil

  defp mismatches(params, shipment) do
    Enum.reduce(@comparison_fields, [], fn {report_key, shipment_key, label}, mismatches ->
      case Map.get(params, report_key) do
        nil ->
          mismatches

        value ->
          if value == Map.get(shipment, shipment_key) do
            mismatches
          else
            mismatches ++ [label]
          end
      end
    end)
  end

  defp unmatched_summary(%{reported_manifest: manifest}) when is_binary(manifest) do
    "no official shipment matched #{manifest}"
  end

  defp unmatched_summary(_params) do
    "no official shipment matched the reported lead"
  end
end
