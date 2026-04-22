defmodule Investigation.LedgerMatcher do
  @moduledoc false

  alias Investigation.Shipment

  @comparison_fields [
    {:reported_manifest, :manifest_number, "manifest"},
    {:trader_id, :trader_id, "trader"},
    {:resource_id, :resource_id, "resource"},
    {:origin_planet_id, :origin_planet_id, "origin"},
    {:destination_planet_id, :destination_planet_id, "destination"}
  ]

  def classify(params) do
    case find_shipment(params) do
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

  defp find_shipment(%{shipment_id: shipment_id}) when is_binary(shipment_id) do
    Ash.read!(Shipment, authorize?: false)
    |> Enum.find(&(&1.id == shipment_id))
  end

  defp find_shipment(%{reported_manifest: manifest}) when is_binary(manifest) do
    Ash.read!(Shipment, authorize?: false)
    |> Enum.find(&(&1.manifest_number == manifest))
  end

  defp find_shipment(_params), do: nil

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
