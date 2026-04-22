defmodule ShadowMarket.Validations.DistinctRoute do
  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def supports(_opts), do: [Ash.Changeset]

  @impl true
  def validate(changeset, opts, _context) do
    left = Ash.Changeset.get_attribute(changeset, opts[:left])
    right = Ash.Changeset.get_attribute(changeset, opts[:right])

    if is_nil(left) or is_nil(right) or left != right do
      :ok
    else
      {:error, field: opts[:right], message: "must differ from #{opts[:left]}"}
    end
  end
end
