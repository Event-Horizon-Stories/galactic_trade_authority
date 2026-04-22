defmodule ContractLoopholes.Shipment do
  use Ash.Resource,
    domain: ContractLoopholes.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_contract_loopholes_shipments)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      primary?(true)

      accept([
        :manifest_number,
        :quantity,
        :declared_value,
        :trader_id,
        :origin_planet_id,
        :destination_planet_id,
        :resource_id
      ])

      validate(match(:manifest_number, ~r/^GTA-\d{4}$/))
      validate(compare(:quantity, greater_than: 0))
      validate(compare(:declared_value, greater_than_or_equal_to: 0))
      change(ContractLoopholes.Changes.ApplyRegulatoryOutcome)
    end

    create :register_with_contract do
      accept([
        :manifest_number,
        :quantity,
        :declared_value,
        :trader_id,
        :origin_planet_id,
        :destination_planet_id,
        :resource_id,
        :contract_id
      ])

      validate(match(:manifest_number, ~r/^GTA-\d{4}$/))
      validate(compare(:quantity, greater_than: 0))
      validate(compare(:declared_value, greater_than_or_equal_to: 0))
      change(ContractLoopholes.Changes.ApplyRegulatoryOutcome)
    end
  end

  code_interface do
    define(:register, action: :register)
    define(:register_with_contract, action: :register_with_contract)
    define(:list, action: :read)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :manifest_number, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :quantity, :integer do
      allow_nil?(false)
      public?(true)
    end

    attribute :declared_value, :integer do
      allow_nil?(false)
      public?(true)
    end

    attribute :tax_due, :integer do
      allow_nil?(false)
      public?(true)
      default(0)
    end

    attribute :route_decision, :atom do
      allow_nil?(false)
      public?(true)
      default(:standard)
      constraints(one_of: [:standard, :tax_exempt, :permitted_by_contract])
    end

    attribute :override_summary, :string do
      public?(true)
    end
  end

  relationships do
    belongs_to :trader, ContractLoopholes.Trader do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :origin_planet, ContractLoopholes.Planet do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :destination_planet, ContractLoopholes.Planet do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :resource, ContractLoopholes.TradeResource do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :contract, ContractLoopholes.Contract do
      attribute_writable?(true)
      public?(true)
    end
  end
end
