defmodule Order.Trader do
  use Ash.Resource,
    domain: Order.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_order_traders)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      primary?(true)
      accept([:callsign, :faction, :reputation, :status])
    end
  end

  code_interface do
    define(:register, action: :register)
    define(:list, action: :read)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :callsign, :string do
      allow_nil?(false)
      public?(true)
      constraints(min_length: 3)
    end

    attribute :faction, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:authority, :guild, :independent])
    end

    attribute :reputation, :integer do
      allow_nil?(false)
      public?(true)
      default(0)
      constraints(min: 0, max: 100)
    end

    attribute :status, :atom do
      allow_nil?(false)
      public?(true)
      default(:registered)
      constraints(one_of: [:registered, :suspended])
    end
  end
end
