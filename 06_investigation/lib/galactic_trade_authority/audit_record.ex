defmodule GalacticTradeAuthority.AuditRecord do
  use Ash.Resource,
    domain: GalacticTradeAuthority.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_investigation_audit_records)
  end

  actions do
    defaults([:read, :destroy])

    create :record do
      primary?(true)

      accept([
        :audit_code,
        :event_type,
        :finding,
        :subject_manifest,
        :summary,
        :recorded_at,
        :actor_id,
        :shipment_id,
        :shadow_report_id
      ])
    end
  end

  code_interface do
    define(:record, action: :record)
    define(:list, action: :read)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :audit_code, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :event_type, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:shipment_registered, :override_reviewed, :shadow_report_recorded])
    end

    attribute :finding, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:approved, :matched, :unmatched, :contradicted])
    end

    attribute :subject_manifest, :string do
      public?(true)
    end

    attribute :summary, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :recorded_at, :utc_datetime_usec do
      allow_nil?(false)
      public?(true)
    end
  end

  relationships do
    belongs_to :actor, GalacticTradeAuthority.Trader do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :shipment, GalacticTradeAuthority.Shipment do
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :shadow_report, GalacticTradeAuthority.ShadowReport do
      attribute_writable?(true)
      public?(true)
    end
  end
end
