defmodule GalacticTradeAuthority.Validations.UniqueManifestNumber do
  @moduledoc """
  Enforces manifest uniqueness within the current tenant.

  Chapter 7 allows the same manifest format to appear in different tenants while
  still forbidding duplicates inside any single tenant ledger.
  """

  use Ash.Resource.Validation

  alias GalacticTradeAuthority.Shipment

  @impl true
  def validate(changeset, _opts, _context) do
    manifest_number = Ash.Changeset.get_attribute(changeset, :manifest_number)

    duplicate? =
      Ash.read!(Shipment, authorize?: false, tenant: changeset.tenant)
      |> Enum.any?(&(&1.manifest_number == manifest_number))

    if duplicate? do
      {:error, field: :manifest_number, message: "has already been registered in this tenant"}
    else
      :ok
    end
  end
end
