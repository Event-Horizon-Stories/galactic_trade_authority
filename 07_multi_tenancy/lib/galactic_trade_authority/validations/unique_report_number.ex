defmodule GalacticTradeAuthority.Validations.UniqueReportNumber do
  use Ash.Resource.Validation

  alias GalacticTradeAuthority.ShadowReport

  @impl true
  def validate(changeset, _opts, _context) do
    report_number = Ash.Changeset.get_attribute(changeset, :report_number)

    duplicate? =
      Ash.read!(ShadowReport, authorize?: false, tenant: changeset.tenant)
      |> Enum.any?(&(&1.report_number == report_number))

    if duplicate? do
      {:error, field: :report_number, message: "has already been recorded in this tenant"}
    else
      :ok
    end
  end
end
