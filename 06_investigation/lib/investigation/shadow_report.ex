defmodule Investigation.ShadowReport do
  use Ash.Resource,
    domain: Investigation.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_investigation_reports)
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
      validate(Investigation.Validations.RequireStructuredLead)
      change(Investigation.Changes.ClassifyLedgerPresence)
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
    belongs_to :shipment, Investigation.Shipment do
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :trader, Investigation.Trader do
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :resource, Investigation.TradeResource do
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :origin_planet, Investigation.Planet do
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :destination_planet, Investigation.Planet do
      attribute_writable?(true)
      public?(true)
    end
  end
end
