defmodule GalacticTradeAuthority.Resources.Trader do
  @moduledoc """
  A registered trade actor inside one tenant's ledger.

  The resource keeps the earlier faction and clearance concepts, but chapter 7
  scopes every trader to one tenant so authority in one sector does not leak
  into another.
  """

  use Ash.Resource,
    domain: GalacticTradeAuthority.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_investigation_traders)
  end

  multitenancy do
    strategy(:context)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      primary?(true)
      accept([:callsign, :faction, :reputation, :status, :override_clearance])
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
      constraints(one_of: [:authority, :guild, :syndicate])
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

    attribute :override_clearance, :boolean do
      allow_nil?(false)
      public?(true)
      default(false)
    end
  end
end
