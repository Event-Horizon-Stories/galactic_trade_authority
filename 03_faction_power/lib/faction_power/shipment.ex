defmodule FactionPower.Shipment do
  use Ash.Resource,
    domain: FactionPower.Registry,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Policy.Authorizer]

  ets do
    private?(false)
    table(:gta_faction_power_shipments)
  end

  actions do
    defaults([:read, :destroy])

    create :register_standard do
      primary?(true)
      accept([:manifest_number, :cargo_name, :declared_value, :trader_id])

      validate(match(:manifest_number, ~r/^GTA-\d{4}$/))
      validate(compare(:declared_value, greater_than_or_equal_to: 0))

      change(set_attribute(:secrecy_level, :standard))
      change(set_attribute(:corridor, :civil))
    end

    create :register_restricted do
      accept([:manifest_number, :cargo_name, :declared_value, :trader_id])

      validate(match(:manifest_number, ~r/^GTA-\d{4}$/))
      validate(compare(:declared_value, greater_than_or_equal_to: 0))

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

    policy action(:register_restricted) do
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
    define(:register_restricted, action: :register_restricted)
    define(:list, action: :read)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :manifest_number, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :cargo_name, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :declared_value, :integer do
      allow_nil?(false)
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
  end

  relationships do
    belongs_to :trader, FactionPower.Trader do
      allow_nil?(false)
      attribute_writable?(true)
      public?(true)
    end
  end
end
