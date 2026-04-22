defmodule GalacticTradeAuthority.Resources.PlanetRule do
  use Ash.Resource,
    domain: GalacticTradeAuthority.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_shadow_market_rules)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      primary?(true)
      accept([:direction, :effect, :tax_rate, :rationale, :planet_id, :resource_id])
    end
  end

  code_interface do
    define(:register, action: :register)
    define(:list, action: :read)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :direction, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:import, :export])
    end

    attribute :effect, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:tax, :ban])
    end

    attribute :tax_rate, :integer do
      public?(true)
      constraints(min: 0, max: 100)
    end

    attribute :rationale, :string do
      allow_nil?(false)
      public?(true)
    end
  end

  relationships do
    belongs_to :planet, GalacticTradeAuthority.Resources.Planet do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :resource, GalacticTradeAuthority.Resources.TradeResource do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end
  end
end
