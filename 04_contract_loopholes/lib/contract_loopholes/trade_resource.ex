defmodule ContractLoopholes.TradeResource do
  use Ash.Resource,
    domain: ContractLoopholes.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_contract_loopholes_resources)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      primary?(true)
      accept([:name, :category])
    end
  end

  code_interface do
    define(:register, action: :register)
    define(:list, action: :read)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :category, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:essential, :industrial, :restricted])
    end
  end
end
