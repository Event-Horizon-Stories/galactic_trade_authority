defmodule GalacticTradeAuthority.TradeResource do
  @moduledoc """
  A trade good defined inside one tenant's version of the ledger.

  Later tenants may classify the same goods differently, so the resource remains
  structurally familiar while the data becomes tenant-specific.
  """

  use Ash.Resource,
    domain: GalacticTradeAuthority.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_investigation_resources)
  end

  multitenancy do
    strategy(:context)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      primary?(true)
      accept([:name, :category, :base_unit, :legal_status])
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

    attribute :base_unit, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :legal_status, :atom do
      allow_nil?(false)
      public?(true)
      default(:legal)
      constraints(one_of: [:legal, :restricted])
    end
  end

  relationships do
    has_many :planet_rules, GalacticTradeAuthority.PlanetRule do
      destination_attribute(:resource_id)
      public?(true)
    end
  end
end
