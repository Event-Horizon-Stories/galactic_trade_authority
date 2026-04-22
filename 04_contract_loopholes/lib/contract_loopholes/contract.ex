defmodule ContractLoopholes.Contract do
  use Ash.Resource,
    domain: ContractLoopholes.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_contract_loopholes_contracts)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      primary?(true)

      accept([
        :contract_code,
        :override_type,
        :rationale,
        :trader_id,
        :resource_id,
        :destination_planet_id
      ])
    end
  end

  code_interface do
    define(:register, action: :register)
    define(:list, action: :read)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :contract_code, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :override_type, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:tax_exemption, :restricted_permit])
    end

    attribute :rationale, :string do
      allow_nil?(false)
      public?(true)
    end
  end

  relationships do
    belongs_to :trader, ContractLoopholes.Trader do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :resource, ContractLoopholes.TradeResource do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :destination_planet, ContractLoopholes.Planet do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end
  end
end
