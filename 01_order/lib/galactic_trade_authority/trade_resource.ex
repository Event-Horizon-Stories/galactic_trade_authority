defmodule GalacticTradeAuthority.TradeResource do
  @moduledoc """
  A category of goods the Authority knows how to classify.

  The opening lesson keeps resource legality simple so the learner can focus on
  how Ash models data shape and sanctioned create actions.
  """

  use Ash.Resource,
    domain: GalacticTradeAuthority.Registry,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(false)
    table(:gta_order_resources)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      primary?(true)
      accept([:name, :category, :base_unit, :legal_status])
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

    attribute :category, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:essential, :industrial, :luxury])
    end

    attribute :base_unit, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :legal_status, :atom do
      allow_nil?(false)
      public?(true)
      default(:legal)
      constraints(one_of: [:legal])
    end
  end
end
