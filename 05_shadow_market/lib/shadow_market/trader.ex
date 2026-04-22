defmodule ShadowMarket.Trader do
  use Ash.Resource,
    domain: ShadowMarket.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_shadow_market_traders)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      primary?(true)

      accept([:callsign, :faction])
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
    end

    attribute :faction, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:guild, :authority, :syndicate])
    end
  end
end
