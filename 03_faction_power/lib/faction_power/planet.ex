defmodule FactionPower.Planet do
  use Ash.Resource,
    domain: FactionPower.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_faction_power_planets)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      primary?(true)
      accept([:name, :sector, :customs_index])
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

    attribute :sector, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :customs_index, :integer do
      allow_nil?(false)
      public?(true)
      constraints(min: 1, max: 5)
    end
  end

  relationships do
    has_many :planet_rules, FactionPower.PlanetRule do
      destination_attribute(:planet_id)
      public?(true)
    end
  end
end
