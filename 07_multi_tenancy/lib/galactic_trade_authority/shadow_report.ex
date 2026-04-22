defmodule GalacticTradeAuthority.ShadowReport do
  use Ash.Resource,
    domain: GalacticTradeAuthority.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_investigation_reports)
  end

  multitenancy do
    strategy(:context)
  end

  actions do
    defaults([:read, :destroy])

    create :record do
      primary?(true)

      accept([
        :report_number,
        :source_type,
        :reported_manifest,
        :reported_quantity,
        :notes,
        :shipment_id,
        :trader_id,
        :resource_id,
        :origin_planet_id,
        :destination_planet_id
      ])

      validate(match(:report_number, ~r/^SR-\d{4}$/))
      validate(GalacticTradeAuthority.Validations.RequireStructuredLead)
      change(GalacticTradeAuthority.Changes.ClassifyLedgerPresence)
    end
  end

  code_interface do
    define(:record, action: :record)
    define(:list, action: :read)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :report_number, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :source_type, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:informant, :sensor, :dock_inspector, :seizure])
    end

    attribute :reported_manifest, :string do
      public?(true)
    end

    attribute :reported_quantity, :integer do
      public?(true)
    end

    attribute :notes, :string do
      public?(true)
    end

    attribute :ledger_status, :atom do
      allow_nil?(false)
      public?(true)
      default(:unmatched)
      constraints(one_of: [:unmatched, :matched, :contradicted])
    end

    attribute :report_summary, :string do
      public?(true)
    end
  end

  relationships do
    belongs_to :shipment, GalacticTradeAuthority.Shipment do
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :trader, GalacticTradeAuthority.Trader do
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :resource, GalacticTradeAuthority.TradeResource do
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :origin_planet, GalacticTradeAuthority.Planet do
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :destination_planet, GalacticTradeAuthority.Planet do
      attribute_writable?(true)
      public?(true)
    end
  end
end
