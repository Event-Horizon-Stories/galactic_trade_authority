defmodule GalacticTradeAuthority.Resources.Shipment do
  use Ash.Resource,
    domain: GalacticTradeAuthority.Registry,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Policy.Authorizer]

  ets do
    private?(false)
    table(:gta_investigation_shipments)
  end

  actions do
    defaults([:read, :destroy])

    create :register_standard do
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
        {GalacticTradeAuthority.Validations.DistinctRoute,
         left: :origin_planet_id, right: :destination_planet_id}
      )

      change(GalacticTradeAuthority.Changes.ApplyRegulatoryOutcome)
      change(set_attribute(:secrecy_level, :standard))
      change(set_attribute(:corridor, :civil))
    end

    create :register_standard_with_contract do
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

      validate(
        {GalacticTradeAuthority.Validations.DistinctRoute,
         left: :origin_planet_id, right: :destination_planet_id}
      )

      change(GalacticTradeAuthority.Changes.ApplyRegulatoryOutcome)
      change(set_attribute(:secrecy_level, :standard))
      change(set_attribute(:corridor, :civil))
    end

    create :register_restricted do
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
        {GalacticTradeAuthority.Validations.DistinctRoute,
         left: :origin_planet_id, right: :destination_planet_id}
      )

      change(GalacticTradeAuthority.Changes.ApplyRegulatoryOutcome)
      change(set_attribute(:secrecy_level, :restricted))
      change(set_attribute(:corridor, :shadow))
    end

    create :register_restricted_with_contract do
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

      validate(
        {GalacticTradeAuthority.Validations.DistinctRoute,
         left: :origin_planet_id, right: :destination_planet_id}
      )

      change(GalacticTradeAuthority.Changes.ApplyRegulatoryOutcome)
      change(set_attribute(:secrecy_level, :restricted))
      change(set_attribute(:corridor, :shadow))
    end
  end

  policies do
    bypass actor_attribute_equals(:faction, :authority) do
      authorize_if(always())
    end

    policy action(:register_standard) do
      forbid_unless(actor_attribute_equals(:status, :registered))
      forbid_unless(relating_to_actor(:trader))
      authorize_if(actor_attribute_equals(:faction, :guild))
      authorize_if(actor_attribute_equals(:faction, :syndicate))
    end

    policy action(:register_standard_with_contract) do
      forbid_unless(actor_attribute_equals(:status, :registered))
      forbid_unless(relating_to_actor(:trader))
      authorize_if(actor_attribute_equals(:faction, :guild))
      authorize_if(actor_attribute_equals(:faction, :syndicate))
    end

    policy action(:register_restricted) do
      forbid_unless(actor_attribute_equals(:status, :registered))
      forbid_unless(relating_to_actor(:trader))
      authorize_if(actor_attribute_equals(:override_clearance, true))
    end

    policy action(:register_restricted_with_contract) do
      forbid_unless(actor_attribute_equals(:status, :registered))
      forbid_unless(relating_to_actor(:trader))
      authorize_if(actor_attribute_equals(:override_clearance, true))
    end

    policy [
      action_type(:read),
      actor_attribute_equals(:status, :registered),
      actor_attribute_equals(:faction, :guild)
    ] do
      authorize_if(expr(trader_id == ^actor(:id) or corridor == :civil))
    end

    policy [
      action_type(:read),
      actor_attribute_equals(:status, :registered),
      actor_attribute_equals(:faction, :syndicate)
    ] do
      authorize_if(expr(trader_id == ^actor(:id) or corridor == :shadow))
    end
  end

  code_interface do
    define(:register_standard, action: :register_standard)
    define(:register_standard_with_contract, action: :register_standard_with_contract)
    define(:register_restricted, action: :register_restricted)
    define(:register_restricted_with_contract, action: :register_restricted_with_contract)
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

    attribute :route_decision, :atom do
      allow_nil?(false)
      public?(true)
      default(:standard)
      constraints(one_of: [:standard, :tax_exempt, :permitted_by_contract])
    end

    attribute :override_summary, :string do
      public?(true)
    end

    attribute :secrecy_level, :atom do
      allow_nil?(false)
      public?(true)
      default(:standard)
      constraints(one_of: [:standard, :restricted])
    end

    attribute :corridor, :atom do
      allow_nil?(false)
      public?(true)
      default(:civil)
      constraints(one_of: [:civil, :shadow])
    end

    attribute :status, :atom do
      allow_nil?(false)
      public?(true)
      default(:registered)
      constraints(one_of: [:registered])
    end
  end

  relationships do
    belongs_to :trader, GalacticTradeAuthority.Resources.Trader do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :origin_planet, GalacticTradeAuthority.Resources.Planet do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :destination_planet, GalacticTradeAuthority.Resources.Planet do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :resource, GalacticTradeAuthority.Resources.TradeResource do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end

    belongs_to :contract, GalacticTradeAuthority.Resources.Contract do
      attribute_writable?(true)
      public?(true)
    end
  end
end
