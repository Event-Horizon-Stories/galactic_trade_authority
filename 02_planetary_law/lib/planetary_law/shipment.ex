defmodule PlanetaryLaw.Shipment do
  use Ash.Resource,
    domain: PlanetaryLaw.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_planetary_law_shipments)
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

      validate(
        {PlanetaryLaw.Validations.DistinctRoute,
         left: :origin_planet_id, right: :destination_planet_id}
      )

      validate(PlanetaryLaw.Validations.AllowedByPlanetaryLaw)
      change(PlanetaryLaw.Changes.ApplyTransitControls)
    end
  end

  code_interface do
    define(:register, action: :register)
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

    attribute :route_classification, :atom do
      allow_nil?(false)
      public?(true)
      default(:standard)
      constraints(one_of: [:standard, :locally_adjusted])
    end

    attribute :compliance_summary, :string do
      public?(true)
    end

    attribute :status, :atom do
      allow_nil?(false)
      public?(true)
      default(:registered)
      constraints(one_of: [:registered])
    end
  end

  relationships do
    belongs_to :trader, PlanetaryLaw.Trader do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :origin_planet, PlanetaryLaw.Planet do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :destination_planet, PlanetaryLaw.Planet do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :resource, PlanetaryLaw.TradeResource do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end
  end
end
